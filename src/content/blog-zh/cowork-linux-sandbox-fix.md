---
title: "Cowork Linux 沙箱启动失败修复方案"
description: "Cowork VM Sandbox（Linux 隔离环境）因 Windows App Package 路径隔离导致启动失败的完整修复步骤。"
pubDate: 2026-05-01
tags: ["Cowork", "Linux", "故障排除"]
---

# Cowork Linux 沙箱启动失败修复方案

## 问题现象

- Bash 命令返回：`Workspace unavailable. The isolated Linux environment failed to start.`
- 或持续显示 "Workspace still starting..." 后最终超时报错

## 根因

Cowork 的 Linux 沙箱依赖 `CoworkVMService`（Windows 服务，以 `LocalSystem` 身份运行），该服务在 **Windows App Package 隔离路径**下查找 VM 文件，但实际文件在标准 AppData 路径下。

| 项目 | 路径 |
|------|------|
| ❌ VM 服务查找路径 | `C:\Users\%USERNAME%\AppData\Local\Packages\Claude_<包标识符>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle\` |
| ✅ 实际文件路径 | `C:\Users\%USERNAME%\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle\` |

VM 服务会**主动拒绝**目录符号链接（Junction），报错 `refusing to open`，因此必须使用 NTFS 硬链接。

## 所需文件清单

| 文件 | 大小 | 说明 |
|------|------|------|
| `rootfs.vhdx` | ~9.4 GB | Linux 根文件系统 |
| `vmlinuz` | ~15 MB | Linux 内核 |
| `initrd` | ~177 MB | 初始 RAM 磁盘 |
| `smol-bin.vhdx` | ~37 MB | 工具/二进制文件 |

## 查找本机包标识符

在 PowerShell 中运行以下命令找到你的 Claude 包文件夹名：

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages\" | Where-Object Name -like "Claude_*" | Select-Object Name
```

## 修复步骤

### 前置条件

1. 关闭 Claude / Cowork 桌面应用
2. 右键 PowerShell → **以管理员身份运行**

### 执行命令

```powershell
# 将 <用户名> 替换为你的 Windows 用户名，<包标识符> 替换为上一步查到的值

# 1. 创建 Package 路径下的目录结构
New-Item -ItemType Directory -Path "C:\Users\<用户名>\AppData\Local\Packages\Claude_<包标识符>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle" -Force

# 2. 为所有 VM 关键文件创建硬链接（不占用额外磁盘空间）
$realPath = "C:\Users\<用户名>\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle"
$linkPath = "C:\Users\<用户名>\AppData\Local\Packages\Claude_<包标识符>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle"

$files = @("rootfs.vhdx", "vmlinuz", "initrd", "smol-bin.vhdx")
foreach ($file in $files) {
    New-Item -ItemType HardLink -Path "$linkPath\$file" -Target "$realPath\$file"
}

# 3. 验证硬链接是否创建成功
Get-ChildItem $linkPath | Select-Object Name, Length, LinkType | Format-Table -AutoSize
```

### 验证

确认每个文件的 `LinkType` 值均为 `HardLink`：

```
Name              Length LinkType
----              ------ --------
initrd         177303315 HardLink
rootfs.vhdx   9453961216 HardLink
smol-bin.vhdx   37748736 HardLink
vmlinuz         14993800 HardLink
```

完成后重启 Claude 桌面应用，沙箱即可正常启动。

## 注意事项

1. **不要使用 Junction/Symlink** — VM 服务会主动拒绝
2. **必须管理员权限** — 硬链接需要管理员身份才能创建
3. **包标识符会变化** — 如果 Claude 重新安装或更新，`Claude_<包标识符>` 可能改变，届时需要重新创建硬链接
4. **硬链接共享磁盘空间** — 它们指向同一份底层数据，不占用额外空间
