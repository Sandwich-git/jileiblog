# Obsidian 集成配置指南

将博客仓库作为 Obsidian 知识库使用，写文章、记笔记、右键一键发布。

---

## 第 1 步：以 vault 方式打开项目

1. 打开 Obsidian
2. **"Open folder as vault"** → 选择 `D:\workspace\blog\obsidian content`
3. 如果弹出"是否信任作者"，选择 **信任**（否则插件无法运行）

> 为什么不是打开 `D:\workspace\blog`？
> 为了避免 Git 仓库文件和 node_modules 干扰 Obsidian 的浏览体验，我们将 vault 设在独立的 `obsidian content` 子目录下。

---

## 第 2 步：安装社区插件

### 开启社区插件

1. **设置 → 社区插件 → 打开"受限模式"**
2. 搜索并安装以下插件：

| 插件 | 用途 |
|------|------|
| **Obsidian Git** | 自动同步到 GitHub |
| **Shell Commands** | 右键文章一键发布到博客 |

> `community-plugins.json` 已预设这两个插件，安装时会自动识别。

---

## 第 3 步：配置 Templates 插件

1. **设置 → 核心插件 → Templates**
2. **Template folder location** 填写：`_templates`
3. 新建文章时，按 `Ctrl+P` → `Templates: Insert template`，选择对应模板

模板说明：

| 模板文件 | 用途 |
|---------|------|
| `new-post-zh` | 中文博客文章（带 title / description / pubDate / tags / draft） |
| `new-post-en` | 英文博客文章 |
| `new-note` | 个人笔记（不上博客） |

---

## 第 4 步：配置 Obsidian Git（自动同步）

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

> 每隔 1 小时自动同步一次 GitHub。
> 也可按 `Ctrl+P` → `Obsidian Git: Create backup` 立即同步。

---

## 第 5 步：配置 Shell Commands（右键发布）

### 创建 Shell Command

1. **设置 → Shell Commands**
2. 点击 **"New shell command"**
3. 填写以下内容：

| 字段 | 值 |
|------|-----|
| **Alias**（右键菜单显示的文字） | `发布到中文博客` |
| **Shell command** | `powershell -File "D:\workspace\blog\publish-to-blog.ps1" -FilePath "{{event_file_path:absolute}}" -TargetLang zh` |
| **Shell type** | `PowerShell` |

4. 点击该命令行的 **齿轮图标（Events）**
5. 勾选 **"File menu"** — 这样在文件上右键时会出现此命令
6. 如果右键菜单显示空白，回到设置 → 勾选 **"Preview variables in command palette and menus"**

### 添加英文博客发布（可选）

同样步骤再建一个命令：

| 字段 | 值 |
|------|-----|
| Alias | `发布到英文博客` |
| Shell command | `powershell -File "D:\workspace\blog\publish-to-blog.ps1" -FilePath "{{event_file_path:absolute}}" -TargetLang en` |
| Shell type | `PowerShell` |
| Events | ✅ File menu |

### 使用方式

在 `文章/` 目录下写完后：
1. 在文件上 **右键**
2. 菜单中点击 **"发布到中文博客"**（或英文）
3. 观察底部状态栏的输出：
   - 文章自动复制到 `src/content/blog-zh/`
   - 自动执行 `npm run build` 检查
   - 自动 `git commit` + `git push`
   - Cloudflare 自动部署
4. 如果提示 `draft: true`，打开复制后的文件将 `draft` 改为 `false` 再发布一次

---

## 第 6 步：开始使用

### 写博客文章

```
文章/              ← 在这里写作（vault 内）
  └── my-post.md
       │
       ▼ 右键 → 发布到中文博客
       │
src/content/blog-zh/  ← 自动复制到这里
  └── my-post.md
       │
       ▼ deploy.ps1 自动执行
       │
GitHub → Cloudflare  ← 自动部署
```

1. 在 `文章/` 目录下新建文件
2. 使用模板 `new-post-zh` 或 `new-post-en` 生成 frontmatter
3. 写完后右键 → **发布到中文博客**
4. 如果文章未完成想先不公开，保持 `draft: true` 即可

### 记个人笔记

1. 在 `笔记/` 目录下新建文件（可以自己创建这个目录）
2. 使用模板 `new-note` 生成元数据
3. 笔记不会出现在博客上，仅供自己查阅
4. 可以使用 `[[wikilink]]` 语法关联笔记

### 插入图片

将图片放入 `public/images/` 目录，文章中引用：

```markdown
![图片描述](/images/文件名.png)
```

> 小技巧：图片可以先放到博客目录的 `public/images/` 下，然后在 Obsidian 中通过 `[[]]` 链接或直接写 Markdown 图片语法引用。

---

## 目录结构一览

```
D:\workspace\blog\              ← Git 仓库根目录
├── obsidian content\           ← Obsidian vault 根目录
│   ├── .obsidian\              ← Obsidian 配置（已预设）
│   ├── _templates\             ← 文章/笔记模板（new-post-zh / new-post-en / new-note）
│   ├── 文章\                   ← 在此写作，右键发布
│   └── 笔记\                   ← 个人笔记（不上博客，可选）
├── src\content\
│   ├── blog-zh\                ← 中文博客文章（自动发布到这里）
│   ├── blog-en\                ← 英文博客文章
│   └── notes\                  ← 个人笔记（不上博客）
├── public\images\              ← 图片资源
├── publish-to-blog.ps1         ← 一键发布脚本
├── deploy.ps1                  ← 构建 + 提交推送脚本
├── new-post.ps1                ← 命令行新建文章
├── CLAUDE.md                   ← 项目说明（给 Claude 用）
└── OBSIDIAN_SETUP.md           ← ← 你正在看的这份指南
```

---

## 发布流程（完整版）

```
写文章                           →  右键 → 发布到中文博客
在 文章/ 目录下写 .md 文件             publish-to-blog.ps1 自动运行：
                                       1. 复制文件到 src/content/blog-zh/
                                       2. npm run build（构建检查）
                                       3. git add + commit + push
                                       4. Cloudflare 自动部署
```

手动部署备用：在 PowerShell 中运行 `cd D:\workspace\blog && .\deploy.ps1`

---

## 常见问题

**Q: 右键菜单没有"发布到中文博客"？**
A: 检查 Shell Commands 设置中是否勾选了 Events → File menu，并确认插件已启用。

**Q: 发布后博客没更新？**
A: 检查 deploy.ps1 的构建是否通过。如果有语法错误，`npm run build` 会失败导致提交中断。Cloudflare 部署需要 1-2 分钟。

**Q: 如何只保存不同步？**
A: Obsidian Git 每 60 分钟自动同步。如果不想推送，临时关闭 Obsidian Git 插件即可。
