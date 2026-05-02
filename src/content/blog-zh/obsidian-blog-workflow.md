---
title: "从 Obsidian 到一键发布：我的博客写作工作流进化之路"
description: "继零成本搭建博客之后，继续记录如何将 Obsidian 作为写作前端，打通从草稿到线上的一键发布流水线——包括 Vault 架构、模板系统、Shell Commands 插件集成、PowerShell 自动化脚本，以及那些爬过的坑。"
pubDate: 2026-05-03
tags: ["博客", "Obsidian", "工作流", "自动化"]
---

# 从 Obsidian 到一键发布：我的博客写作工作流进化之路

## 引言

在上一篇文章中，我记录了使用 **Astro 5 + Cloudflare Pages** 零成本搭建 jilei.blog 的过程。博客上线后，写作体验成了新的瓶颈：

- 每次写文章要在 VS Code 和浏览器之间反复切换
- 文章图片要手动处理路径
- 部署要敲命令行，不够流畅
- 笔记和文章混在一起，缺少管理层次

于是我开始思考：能不能把写作体验提升到和 Medium、Notion 一样流畅，同时保留对内容的完全控制权？

答案就是 **Obsidian + 自动化流水线**。本文完整记录这个方案的架构设计与实现过程。

---

## 为什么选择 Obsidian

选型时我列了几个关键需求：

| 需求 | 要求 |
|------|------|
| **本地优先** | 文章数据完全归自己，不依赖云端服务 |
| **跨平台** | 同时支持 Windows 和 macOS |
| **Markdown 原生** | 与 Astro 的内容体系天然兼容 |
| **可扩展** | 有插件生态，能接入自动化流程 |
| **知识库能力** | 写文章的同时能记笔记、建知识关联 |

Obsidian 完美命中所有需求。尤其是它的 **插件系统** 和 **社区插件生态**，让我能自建一套发布流水线，而不只是把它当作一个 Markdown 编辑器。

---

## 整体架构

最终方案的核心思路是 **分离关注点**：

```
写作层（Obsidian）    →    发布层（PowerShell）    →    部署层（GitHub + Cloudflare）
    │                          │                          │
    │  文章/ 目录写作          │  校验 frontmatter        │  git push 触发
    │  模板自动生成           │  去除 draft 状态         │  Cloudflare 自动构建
    │  本地笔记不上传          │  npm run build 检查      │  约 1-2 分钟上线
    │                          │  git commit + push       │
    ▼                          ▼                          ▼
   obsidian content/       publish-to-blog.ps1        GitHub → Cloudflare
```

---

## Vault 架构设计

### 目录结构

第一个要解决的是 **仓库文件与写作文件的共存问题**。博客根目录下有 `node_modules`、`src/`、`package.json` 等大量与写作无关的文件，直接作为 Obsidian vault 会非常杂乱。

解决方案是将 vault 设在独立子目录中：

```
blog/                          ← Git 仓库根目录
├── obsidian content/          ← Obsidian vault（.gitignore）
│   ├── .obsidian/             ← Obsidian 配置
│   ├── _templates/            ← 文章/笔记模板
│   ├── 文章/                  ← 博客文章
│   └── 笔记/                  ← 个人笔记（不上博客）
├── src/content/
│   ├── blog-zh/               ← 中文博客文章（自动发布目标）
│   ├── blog-en/               ← 英文博客文章
│   └── notes/                 ← 个人笔记（不上博客）
├── publish-to-blog.ps1        ← 一键发布脚本
└── deploy.ps1                 ← 构建 + 提交推送
```

这样做有几个好处：

1. **Obsidian 中只看到写作相关内容**，没有代码文件的干扰
2. **笔记与文章分离**，个人笔记不会误发布
3. **通过 `.gitignore` 排除整个 vault 目录**，个人草稿和 Obsidian 插件二进制文件不上传到公开仓库

### 为什么要将 vault 从 Git 中排除

这是一个重要的决策。`obsidian content/` 目录包含：

- **个人笔记** — 不属于博客内容
- **草稿状态的文章** — 未完成时不希望公开
- **Obsidian 插件二进制文件** — `main.js` 等不应提交到仓库
- **工作区状态文件** — `workspace.json`、`workspace-mobile.json`

所以在 `.gitignore` 中排除了整个目录：

```
obsidian content/
```

搭配 **Obsidian Git 插件**，写作内容依然通过 GitHub 备份——区别是不在公开仓库中，而是 Obsidian 自己管理的同步流程。

---

## 模板系统

模板是提升写作效率的关键。Obsidian 核心插件 **Templates** 可以根据模板文件自动生成 frontmatter。

### 中文文章模板

```markdown
---
title: "{{title}}"
description: "在此填写文章简介，用于 SEO 和文章卡片展示，建议 120 字以内"
pubDate: 2026-05-03
tags: []
---
```

关键设计点：

- **模板变量**：`{{title}}` 和 `{{date:YYYY-MM-DD}}` 是 Obsidian 模板变量，插入时自动替换
- **draft 字段已移除**：发布即公开，避免忘记改状态
- **description 有占位文案**：提醒填写，而非留空

### 关于 draft 的处理策略

Astro 的 content collection schema 中 `draft` 默认值为 `false`（公开）。但很多工作流中会建议在模板里写 `draft: true`，发布前再改为 `false`。

我选择 **不在模板中写 draft 字段**，而是在发布脚本中自动处理：如果文章中有 `draft: true`，复制到发布目录时自动去除。这样：

- 用户仍然可以在原文件中用 `draft: true` 标记未完成
- 发布版本**一定是公开的**，不会因为忘记改状态而发布了一篇空文章

---

## 一键发布流水线

这是整个方案的核心。目标是：**在 Obsidian 中右键文章 → 自动完成校验、复制、构建、部署**。

### 第一步：Shell Commands 插件

**Obsidian Shell Commands** 是一个社区插件，允许在 Obsidian 中执行自定义 shell 命令，并支持：

- **File menu 事件** — 在文件右键菜单中添加自定义命令
- **`{{event_file_path:absolute}}` 变量** — 获取右键点击的文件路径
- **多 shell 支持** — CMD、PowerShell 5、PowerShell Core

配置方式：

| 字段 | 值 |
|------|-----|
| Alias | 发布到中文博客 |
| Shell command | `powershell -File "D:\workspace\blog\publish-to-blog.ps1" -FilePath "{{event_file_path:absolute}}" -TargetLang zh` |
| Shell type | PowerShell |
| Events | ✅ File menu |

设置后，在 `文章/` 目录下任意 `.md` 文件上右键，就能看到自定义的"发布到中文博客"菜单项。

### 第二步：PowerShell 发布脚本

`publish-to-blog.ps1` 是串联整个流水线的核心。它的工作流程如下：

```
接收文件路径
    ↓
校验 frontmatter（title / description / pubDate 必填）
    ↓
复制文件到 src/content/blog-zh/
    ↓
自动去除 draft: true（如果有）
    ↓
执行 deploy.ps1（npm run build → git commit → git push）
    ↓
Cloudflare 自动部署
```

脚本的关键功能：

**Frontmatter 校验**：如果缺少必填字段，给出明确的错误提示并中止流程，避免浪费构建时间：

```
[ERROR] Missing frontmatter: description, pubDate
```

**自动公开**：如果文章包含 `draft: true`，复制后自动去除该行，确保发布版本可见。

**错误处理**：`npm run build` 失败时中止推送，防止破坏线上版本。

### 第三步：Git 操作与部署

`deploy.ps1` 负责构建检查与 Git 操作：

```powershell
npm run build                    # 构建检查
git add -A                       # 暂存所有变更
git commit -m "update: 文章名"    # 提交
git push                         # 推送 → Cloudflare 自动部署
```

这样，从右键发布到线上生效，只需要 **一次点击**。

---

## 遇到的坑与解决方案

### 1. PowerShell 的 `---` 解析问题

在脚本中使用包含 `---` 的字符串时，PowerShell 解析器会报语法错误：

```powershell
# ❌ 这行代码会导致解析错误
if ($content -match "^---\s*\n(.*?\n)---\s*\n") { ... }

# ❌ 这行也一样
Write-Host "[ERROR] No frontmatter (---) found in the article!"
```

**原因**：PowerShell 将 `---` 中的 `--` 解析为递减运算符，导致表达式不完整。

**解决方案**：将 `---` 存入变量，用 `StartsWith()` 等方法替代正则匹配：

```powershell
$seperator = "---"
if (-not $content.StartsWith($seperator)) { ... }
```

### 2. Git 在 Linux 沙箱中的 VHDX 兼容性问题

开发环境使用了基于 VHDX 的 Linux 沙箱。在这个环境中执行 `git commit` 会导致对象存储损坏：

```
error: improper chunk offset(s)
error: cache entry has null sha1
```

**原因**：VHDX 文件系统不完全支持 Git 所需的 HardLink 操作。

**解决方案**：
- 所有 Git 操作（提交、推送）在 **Windows PowerShell** 中执行
- 准备了一个 `git-commit-all.ps1` 脚本，自动修复索引并提交
- 代码编辑和脚本执行仍可在沙箱中进行

### 3. Obsidian 社区插件配置同步

`community-plugins.json` 预设了需要的插件列表（Obsidian Git、Shell Commands），但插件本身的二进制文件（`main.js`）需要在 Obsidian 中手动安装。

**原因**：插件二进制文件在 `.gitignore` 中被排除（`plugins/` 目录），无法通过仓库分发。

**解决方案**：`OBSIDIAN_SETUP.md` 中详细说明了安装步骤，用户只需搜索安装即可。

### 4. Astro Content Collections 的 notes 警告

添加 `src/content/notes/` 目录后，Astro 抛出告警：

```
Auto-generating collections for folders in "src/content/" that
are not defined as collections. This is deprecated.
```

**解决方案**：在 `src/content/config.ts` 中定义 notes collection：

```typescript
const noteSchema = z.object({
  created: z.date().optional(),
  tags: z.array(z.string()).default([]),
});

export const collections = {
  'blog-zh': defineCollection({ schema: blogSchema }),
  'blog-en': defineCollection({ schema: blogSchema }),
  'notes': defineCollection({ schema: noteSchema }),
};
```

---

## 最终工作流一览

### 写文章

```
1. 打开 Obsidian，在 文章/ 目录新建文件
2. 按 Ctrl+P → Templates: Insert template → new-post-zh
3. 填入 title、description、正文
```

### 发布

```
4. 文件上右键 → 发布到中文博客
```

### 自动完成

```
5. 脚本校验 frontmatter → 通过后复制到 blog-zh/
6. 自动去除 draft: true
7. npm run build 检查
8. git commit + push
9. Cloudflare 自动部署（约 1-2 分钟）
```

### 记笔记

```
1. 在 笔记/ 目录新建文件
2. 使用 new-note 模板
3. 自由书写，使用 [[wikilink]] 关联笔记
4. 笔记不会出现在博客上
```

---

## 总结

这套方案的核心思路是 **用工具链的整合来消除摩擦**。我刻意避免了：

- ❌ 自己写 Obsidian 插件（维护成本高）
- ❌ 引入 CI/CD 平台（增加复杂度）
- ❌ 使用第三方发布服务（数据不自主）

而是充分利用了：

- ✅ **Obsidian 插件生态** — Shell Commands 提供了右键菜单集成
- ✅ **PowerShell 脚本** — 足以完成文件操作、校验、调用 Git
- ✅ **GitHub + Cloudflare 的自动部署** — 推送即发布，零运维

最终效果是：**写一篇文章 → 右键一次 → 等两分钟，线上可见**。没有任何手动步骤，也没有任何中间平台。

目前这个方案已经在 jilei.blog 上稳定运行。如果你也在用 Astro + Obsidian 的组合，希望这篇文章能帮你少走一些弯路。

> 后续计划：增加图片优化流水线（自动压缩并复制到 `public/images/`），以及文章发布后的 SEO 自动检测。

---

*本文通过这套工作流从 Obsidian 一键发布。* 😄
