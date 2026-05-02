# jilei.blog — Claude 项目说明

## 项目技术栈
- Astro 5 + Tailwind CSS 4
- Cloudflare Pages 托管
- Giscus 评论区（基于 GitHub Discussions）

## 内容存放位置
```
中文博客文章 → src/content/blog-zh/*.md
英文博客文章 → src/content/blog-en/*.md
个人笔记     → src/content/notes/*.md  ← 不上博客
静态资源     → public/
图片资源     → public/images/
组件         → src/components/
布局         → src/layouts/
Obsidian 配置 → .obsidian/
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
- 本项目可作为 Obsidian vault 直接打开
- `.obsidian/templates/` 内置文章/笔记模板
- `src/content/notes/` 下的个人笔记不会出现在博客上
- 参考 `OBSIDIAN_SETUP.md` 完成配置
