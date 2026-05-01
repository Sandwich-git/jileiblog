# jilei.blog

使用 Claude 的心得与技术分享 | Tips and solutions for using Claude

## 技术栈

- **Astro 5** — 静态站点生成器
- **Tailwind CSS 4** — 样式框架
- **Cloudflare Pages** — 托管与 CDN
- **GitHub** — 版本管理

## 本地开发

```bash
npm install
npm run dev     # 启动开发服务器 http://localhost:4321
npm run build   # 构建生产版本到 dist/
npm run preview # 本地预览构建结果
```

## 写文章

在 `src/content/blog-zh/` 或 `src/content/blog-en/` 创建 `.md` 文件，Frontmatter 格式：

```markdown
---
title: 文章标题
description: 文章简介
pubDate: 2026-05-01
tags: ["标签1", "标签2"]
---
```

## 部署

推送到 GitHub main 分支后，Cloudflare Pages 自动构建部署。
