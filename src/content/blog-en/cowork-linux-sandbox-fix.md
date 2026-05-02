---
title: "Cowork Linux Sandbox Startup Failure Fix"
description: "Complete steps to fix Cowork VM Sandbox startup failures caused by Windows App Package path isolation."
pubDate: 2026-05-01
tags: ["Cowork", "Linux", "Troubleshooting"]
---

# Cowork Linux Sandbox Startup Failure Fix

## Symptoms

- Bash commands return: `Workspace unavailable. The isolated Linux environment failed to start.`
- Or repeatedly shows "Workspace still starting..." and eventually times out

## Root Cause

Cowork's Linux sandbox relies on `CoworkVMService` (a Windows service running as `LocalSystem`). This service looks for VM files under the **Windows App Package isolated path**, while the actual files are stored under the standard AppData location.

| Item | Path |
|------|------|
| ❌ VM service looks here | `C:\Users\%USERNAME%\AppData\Local\Packages\Claude_<package_suffix>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle\` |
| ✅ Actual file location | `C:\Users\%USERNAME%\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle\` |

The VM service **actively rejects** directory junctions and symlinks with the error: `path is a symlink or junction, refusing to open`. This means NTFS hard links are the only viable workaround.

## Required Files

| File | Size | Description |
|------|------|-------------|
| `rootfs.vhdx` | ~9.4 GB | Linux root filesystem |
| `vmlinuz` | ~15 MB | Linux kernel |
| `initrd` | ~177 MB | Initial RAM disk |
| `smol-bin.vhdx` | ~37 MB | Utility binaries |

## Finding Your Package Suffix

Run this in PowerShell to find your Claude package folder name:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages\" | Where-Object Name -like "Claude_*" | Select-Object Name
```

## Fix Steps

### Prerequisites

1. Close the Claude / Cowork desktop app
2. Right-click PowerShell → **Run as Administrator**

### Commands

```powershell
# Replace <username> with your Windows username and <package_suffix> with the value from above.

# 1. Create the target directory structure
New-Item -ItemType Directory -Path "C:\Users\<username>\AppData\Local\Packages\Claude_<package_suffix>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle" -Force

# 2. Create hard links for all VM files (zero additional disk usage)
$realPath = "C:\Users\<username>\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle"
$linkPath = "C:\Users\<username>\AppData\Local\Packages\Claude_<package_suffix>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle"

$files = @("rootfs.vhdx", "vmlinuz", "initrd", "smol-bin.vhdx")
foreach ($file in $files) {
    New-Item -ItemType HardLink -Path "$linkPath\$file" -Target "$realPath\$file"
}

# 3. Verify hard links
Get-ChildItem $linkPath | Select-Object Name, Length, LinkType | Format-Table -AutoSize
```

### Verification

Check that each file has `LinkType` set to `HardLink`:

```
Name              Length LinkType
----              ------ --------
initrd         177303315 HardLink
rootfs.vhdx   9453961216 HardLink
smol-bin.vhdx   37748736 HardLink
vmlinuz         14993800 HardLink
```

Restart the Claude desktop app. The sandbox should now start correctly.

## Important Notes

1. **Junctions / symlinks will NOT work** — the VM service explicitly refuses them
2. **Administrator rights required** — hard link creation needs elevation
3. **Package suffix changes on reinstall** — if Claude gets updated or reinstalled, the `Claude_<package_suffix>` identifier may change, requiring a repeat of this procedure
4. **Hard links share disk space** — they point to the same on-disk data, taking no additional space
