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
description: "简介（显示在文章卡片和搜索引擎结果中）"
pubDate: 2026-05-02
tags: ["标签1", "标签2"]
# 可选字段
updatedDate: 2026-05-03      # 更新日期
draft: true                   # true 则不显示在列表中
---
```

## 写文章的约束
- 文件名即 slug（URL 路径），用英文短横线命名，如 `zero-cost-blog-setup.md`
- 中文和英文文章可以同名文件放在不同目录下，表示互为翻译版本
- description 控制在 120 字以内，用于 SEO
- 代码块不需要指定语言也可以正常显示

## 可用脚本
```powershell
.\new-post.ps1 -Title "文章标题"           # 新建文章草稿
.\deploy.ps1                              # 构建检查 + 提交推送
npm run dev                               # 本地预览
npm run build                             # 生产构建
```

## 部署方式
推送到 GitHub main 分支 → Cloudflare Pages 自动构建部署

## Obsidian 集成
- Vault 路径：`obsidian content/`（独立子目录，避免 Git 文件干扰）
- 在 `文章/` 目录下写作，右键 → 发布到中文/英文博客
- 发布脚本：`publish-to-blog.ps1`（复制到 src/content/blog-* + 执行 deploy.ps1）
- 模板位置：`obsidian content/_templates/`（new-post-zh / new-post-en / new-note）
- 社区插件依赖：Obsidian Git + Shell Commands
- 参考 `OBSIDIAN_SETUP.md` 完成配置
