---
title: "零成本搭建个人技术博客全记录 —— Astro + Cloudflare Pages 实战"
description: "从域名购买到评论区上线，记录使用 Astro、GitHub 和 Cloudflare Pages 搭建 jilei.blog 的完整过程与踩坑总结。"
pubDate: 2026-05-02
tags: ["博客", "Astro", "Cloudflare", "教程"]
---

# 零成本搭建个人技术博客全记录

## 缘起

一直想有一个自己的技术博客，用来分享使用 Claude 的心得和问题解决方案。市面上有很多选择——Hexo、WordPress、Medium、掘金……但我的需求比较明确：

- **成本极低** —— 不想为博客每月付钱
- **内容自主** —— 文章数据完全归自己，不依赖任何平台
- **适合中文读者** —— 要考虑国内访问速度
- **技术范儿** —— 想用自己喜欢的工具链来搭建

经过比较，最终选择了 **Astro + GitHub + Cloudflare Pages** 的组合。这篇文章就是整个搭建过程的完整记录，包括那些让人头疼的坑。

---

## 方案选型

| 模块 | 选择 | 成本 |
|------|------|------|
| 框架 | Astro 5 | ¥0 |
| 样式 | Tailwind CSS 4 | ¥0 |
| 托管 | Cloudflare Pages | ¥0 |
| 版本管理 | GitHub（私有仓库） | ¥0 |
| 评论系统 | Giscus（基于 GitHub Discussions） | ¥0 |
| 域名 | jilei.blog | ¥59/年 |
| **合计** | | **首年 ¥59** |

架构很简单：

```
本地写作 (Markdown) → Git 推送 → Cloudflare Pages 构建 → 全球 CDN 分发
```

纯静态站点，没有服务器，没有数据库，没有运维成本。

---

## 第一步：域名选择

域名选了 **jilei.blog**。真名做域名，时间越久越有价值。

---

## 第二步：域名 DNS 配置

这里踩了第一个坑。

域名在聚域购买后，DNS 需要交给 Cloudflare 管理——这样才能用 Cloudflare Pages 的免费 CDN 和 HTTPS。

操作流程：

```
聚域 → 修改 Nameserver → 指向 Cloudflare
```

Cloudflare 会给两个 Nameserver 地址：

```
augustus.ns.cloudflare.com
meilani.ns.cloudflare.com
```

在聚域的域名管理后台找到 **DNS 服务器修改**，替换为 Cloudflare 的地址即可。

> **注意**：DNS 变更生效需要 10 分钟到数小时不等，耐心等待。

---

## 第三步：搭建博客项目

这一步是我用 Claude 辅助完成的——我说需求，Claude 生成代码，整个项目模板 30 分钟就搭好了。

**项目结构要点：**

```
src/
├── content/
│   ├── blog-zh/       ← 中文文章（Markdown）
│   └── blog-en/       ← 英文文章（Markdown）
├── layouts/
│   └── PostLayout.astro  ← 文章页面布局
├── components/        ← 可复用组件
└── pages/             ← 路由页面
```

**中英双语方案：**

我用 Astro 内置的 i18n 功能。中文和英文文章分两个集合存放，URL 路径区分：

- `jilei.blog/zh/blog/xxx` —— 中文
- `jilei.blog/en/blog/xxx` —— 英文

根路径 `jilei.blog` 自动 301 重定向到 `/zh/`。

**中文排版优化：**

中文的阅读习惯和英文不同，几个关键参数：

```css
article {
  font-size: 1.0625rem;   /* 17px 中文最舒适 */
  line-height: 1.8;        /* 中文行高要大一些 */
  letter-spacing: 0.02em;  /* 增加字间距 */
}
```

---

## 第四步：部署到 Cloudflare Pages

部署本身很简单：

1. 本地 `git push` 推送到 GitHub
2. Cloudflare Pages 连接 GitHub 仓库
3. 保持默认配置点击部署，1-2 分钟即可完成

之后设置自定义域名 `jilei.blog`，Cloudflare 自动配置 SSL 证书。

---

## 第五步：添加评论系统（踩坑最多的环节）

我选择了 **Giscus**——基于 GitHub Discussions，无后端、零成本。但正因为免费，国内访问存在一些问题。

### 坑 1：`document.currentScript` 兼容问题

最初的 Giscus 组件使用 `document.currentScript.parentNode` 来定位容器。在本地开发环境一切正常，但线上就是找不到。

**原因**：Astro 的构建优化在特定情况下改变了脚本的执行上下文，导致 `currentScript` 指向不对。

**解决**：改用固定 `id` 容器 + `getElementById` 获取，更可靠。

```html
<div id="giscus-comments"></div>
<script>
  const container = document.getElementById('giscus-comments');
  // 注入 Giscus 脚本...
</script>
```

### 坑 2：组件被构建优化吞掉

即使修复了脚本逻辑，线上页面源码里仍然找不到 Giscus 组件。排查后发现，`<script is:inline>` 这个 Astro 指令在构建时没有按预期输出。

**解决**：去掉 `is:inline`，改用普通 `<script>` 标签，让 Astro 按默认方式打包到页面底部加载。

### 坑 3：Giscus 在国内的访问问题

这是最大的问题——`giscus.app` 域名在国内被墙。不开 VPN 时，评论区完全加载不出来：

```
Failed to load resource: net::ERR_CONNECTION_RESET
```

即使开了 VPN 让脚本正常加载，也踩了前面两个坑导致评论区不显示。

**现状**：Giscus 本身能正常工作，但国内需要代理才能访问。如果你在国内访问此博客时看不到评论区，说明需要代理。

> 如果评论区对你很重要，可以考虑换 Twikoo（后端部署在 Vercel + MongoDB，国内部分地区可访问）或 Waline（支持 LeanCloud 国内版）。这两个方案我后续可能会迁移。

---

## 第六步：Git 版本管理的小插曲

整个项目文件在 Linux 沙箱中创建和初始化，然后复制到 Windows 机器。这就导致了一个典型问题：

**esbuild 二进制文件不兼容**：不同平台的 esbuild 二进制文件不同。跨平台复制后，在 Windows 上执行时报 `EFTYPE` 错误。

**解决**：删掉 `node_modules` 重新安装，esbuild 会自动下载 Windows 对应版本。

另外因为 `.gitignore` 文件在文件复制过程中丢失，导致 `node_modules` 被 Git 跟踪，出现大量的 LF→CRLF 换行符警告。重建 `.gitignore` 后用 `git rm -r --cached node_modules` 取消跟踪即可。

---

## 最终成本汇总

| 项目 | 费用 | 备注 |
|------|------|------|
| jilei.blog 域名 | ¥59/年 | |
| Cloudflare Pages | ¥0 | 无限带宽、自动 HTTPS |
| GitHub | ¥0 | 公开仓库即可 |
| Astro + Tailwind | ¥0 | 开源框架 |
| Giscus 评论 | ¥0 | 基于 GitHub Discussions |
| **首年合计** | **¥59** | 后续续费相同 |

---

## 总结与建议

这次搭建踩了不少坑，但最终成果是满意的。几个值得分享的经验：

1. **域名用真名** —— 短期看不明显，长期来看最有品牌价值
2. **静态站点生成器首推 Astro** —— 性能好，开发体验好，对 Claude 辅助友好
3. **Cloudflare Pages 对个人博客完全够用** —— 免费计划不限流量
4. **Markdown 写作是最自由的** —— 数据在你手里，随时可以迁移
5. **别怕踩坑** —— 每个坑都是未来文章的好素材

现在博客已上线，后续会持续分享 Claude 使用技巧、AI 工作流搭建经验和各种技术踩坑记录。欢迎通过评论区交流。

---

*这篇文章本身就是用 Claude 辅助完成的——把我的对话记录提炼成文章，然后手动调整润色。后续会写一篇关于这个工作流的详细分享。*
