# Obsidian 集成配置指南

将博客仓库作为 Obsidian 知识库使用，写文章、记笔记、一键发布。

---

## 第 1 步：以 vault 方式打开项目

1. 打开 Obsidian
2. **"Open folder as vault"** → 选择本项目的根目录（`D:\workspace\blog`）
3. 如果弹出"是否信任作者"，选择 **信任**（否则插件无法运行）

## 第 2 步：确认插件设置

Obsidian 会自动读取 `.obsidian/` 下的配置，包括已启用的核心插件。
你只需要手动操作两步：

### 开启社区插件

1. **设置 → 社区插件 → 打开"受限模式"**
2. **浏览** → 搜索并安装 **"Obsidian Git"**
3. 安装后启用

### 配置 Templates 插件

1. **设置 → 核心插件 → Templates**
2. **Template folder location** 填写：`.obsidian/templates/`

## 第 3 步：配置 Obsidian Git（自动同步）

1. **设置 → Obsidian Git**
2. 推荐配置：

| 选项 | 值 |
|------|-----|
| Vault commit message | `update: {{date}}` |
| Auto commit interval (minutes) | `60` |
| Auto pull interval (minutes) | `60` |
| Auto push interval (minutes) | `60` |
| Pull changes on startup | ✅ 开启 |
| Push on backup | ✅ 开启 |

> 这样设置后，Obsidian 每隔 1 小时自动同步一次 GitHub。
> 也可以手动按 `Ctrl+P` → `Obsidian Git: Create backup` 立即同步。

## 第 4 步：开始使用

### 写博客文章

1. 在 `src/content/blog-zh/`（中文）或 `src/content/blog-en/`（英文）目录下新建文件
2. 使用模板 `new-post-zh` 或 `new-post-en` 自动生成 frontmatter
3. 写完将 `draft: false` 即可发布

### 记个人笔记

1. 在 `src/content/notes/` 目录下新建文件
2. 使用模板 `new-note` 自动生成元数据
3. 笔记不会出现在博客上，仅供自己查阅
4. 可以使用 Obsidian 的 `[[wikilink]]` 语法关联笔记

### 插入图片

将图片放入 `public/images/` 目录，文章中引用：

```markdown
![图片描述](/images/文件名.png)
```

## 目录结构一览

```
blog/
├── .obsidian/              # Obsidian 配置（已预设）
│   └── templates/          # 文章/笔记模板
├── src/content/
│   ├── blog-zh/            # 中文博客文章（公开）
│   ├── blog-en/            # 英文博客文章（公开）
│   └── notes/              # 个人笔记（不上博客）
└── public/
    └── images/             # 图片资源
```

## 发布流程

```
Obsidian 写文章 → 改 draft: false → 自动 Git 同步 → Cloudflare 部署
```

或者手动运行 `.\deploy.ps1` 一键推送。
