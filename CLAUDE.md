# jilei.blog — Claude 项目说明

## 项目技术栈
- Astro 5 + Tailwind CSS 4
- Cloudflare Pages 托管
- Giscus 评论区（基于 GitHub Discussions）

## 目录结构
```
blog/                       ← Git 仓库根目录
├── obsidian content/       ← Obsidian vault 根目录
│   ├── .obsidian/          ← Obsidian 配置
│   ├── _templates/         ← 文章/笔记模板
│   ├── 文章/               ← 在此写作，右键发布到博客
│   └── 笔记/               ← 个人笔记（不上博客）
├── src/content/
│   ├── blog-zh/            ← 中文博客文章（自动发布目标）
│   ├── blog-en/            ← 英文博客文章
│   └── notes/              ← 个人笔记（不上博客）
├── public/images/          ← 图片资源
├── publish-to-blog.ps1     ← Obsidian 右键发布脚本
├── deploy.ps1              ← 构建 + 提交推送
└── CLAUDE.md
```

## 文章 Frontmatter 格式
```yaml
---
title: "标题"
description: "简介（显示在文章卡片和搜索引擎结果中，120 字以内）"
pubDate: 2026-05-02
tags: ["标签1", "标签2"]
# 可选字段
updatedDate: 2026-05-03      # 更新日期
---
```
> `draft` 字段不在模板中，发布即公开。发布脚本会自动去除 `draft: true`。

## 文章工作流（推荐：Obsidian 一键发布）

### 写文章
1. 打开 Obsidian，在 `obsidian content/文章/` 目录下新建 `.md` 文件
2. 按 `Ctrl+P` → `Templates: Insert template` → `new-post-zh`（中文）或 `new-post-en`（英文）
3. 填写 `title`、`description`、正文
4. description 控制在 120 字以内，用于 SEO
5. 文件名即 slug（URL 路径），用英文短横线命名，如 `zero-cost-blog-setup.md`
6. 中文和英文文章同名表示互为翻译版本

### 发布
- **方式一（推荐）**：在 Obsidian 中右键文件 → **发布到中文博客**（或英文）
  - 依赖 Shell Commands 插件，调用 `publish-to-blog.ps1`
  - 自动完成：校验 frontmatter → 去除 draft → 复制到 src/content/blog-* → 部署
- **方式二**：`.\new-post.ps1 -Title "标题"` 新建草稿 + `.\deploy.ps1` 手动部署
- **直接方式**：将 `.md` 文件放入 `src/content/blog-zh/` 或 `blog-en/`，然后运行 `.\deploy.ps1`

### 注意事项
- 文章必须有完整的 frontmatter：`title`、`description`、`pubDate` 必填
- 发布脚本会自动去除 `draft: true`，确保发布版本公开
- 图片放入 `public/images/`，文章中引用 `![描述](/images/文件名.png)`
- 所有 git 操作在 **Windows PowerShell** 中执行，不要在 Linux 沙箱中操作 git（VHDX 兼容性问题）
- 代码块不需要指定语言也可以正常显示

### 个人笔记
- 放在 `obsidian content/笔记/` 或 `src/content/notes/` 目录下
- 使用 `new-note` 模板
- 笔记不出现在博客上

## 可用脚本
```powershell
.\new-post.ps1 -Title "文章标题"               # 新建文章草稿
.\publish-to-blog.ps1 -FilePath "..."          # 发布单篇文章到博客
.\deploy.ps1                                   # 构建检查 + 提交推送
.\git-commit-all.ps1                            # 修复 git 索引 + 提交推送
npm run dev                                     # 本地预览
npm run build                                   # 生产构建
```

## 部署方式
推送到 GitHub main 分支 → Cloudflare Pages 自动构建部署

## Obsidian 集成（快速参考）
- **Vault 路径**：`obsidian content/`（独立子目录，不干扰 Git 仓库）
- **写作目录**：`obsidian content/文章/`，右键 → 发布到中文/英文博客
- **模板路径**：`obsidian content/_templates/`（new-post-zh / new-post-en / new-note）
- **发布脚本**：`publish-to-blog.ps1`（校验 frontmatter → 复制 → 部署）
- **插件依赖**：Obsidian Git（同步）+ Shell Commands（右键发布）
- **Obsidian Git 配置**：60 分钟自动 commit/pull/push
- **完整指南**：参考 `OBSIDIAN_SETUP.md`
