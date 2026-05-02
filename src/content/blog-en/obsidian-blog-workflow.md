---
title: "From Obsidian to Live: Building a One-Click Blog Publishing Pipeline"
description: "After setting up a zero-cost blog with Astro and Cloudflare, I built an Obsidian-based writing workflow with one-click publishing — covering vault architecture, template system, Shell Commands integration, PowerShell automation, and the pitfalls along the way."
pubDate: 2026-05-03
tags: ["blog", "Obsidian", "workflow", "automation"]
---

# From Obsidian to Live: Building a One-Click Blog Publishing Pipeline

## Introduction

After getting jilei.blog up and running with Astro 5 and Cloudflare Pages, the writing experience became the next bottleneck:

- Constant tab-switching between VS Code and the browser
- Manual image path handling
- Command-line deployment friction
- No separation between articles and personal notes

I wanted a writing experience as smooth as Medium or Notion, while keeping full control over my content. The answer was **Obsidian + an automated pipeline**. This article documents the architecture and implementation.

---

## Why Obsidian

My requirements were straightforward:

| Requirement | Why |
|-------------|-----|
| **Local-first** | Full ownership of content, no cloud dependency |
| **Cross-platform** | Windows and macOS support |
| **Native Markdown** | Direct compatibility with Astro's content system |
| **Extensible** | Plugin ecosystem for automation |
| **Knowledge base** | Note-taking alongside article writing |

Obsidian checked every box. Its plugin system, especially **Shell Commands**, made it possible to build a custom publishing pipeline without writing a single Obsidian plugin.

---

## Architecture Overview

The core idea is **separation of concerns**:

```
Writing Layer (Obsidian)  →  Publishing Layer (PowerShell) →  Deployment (GitHub + CF)
         │                            │                             │
    Write in 文章/            Validate frontmatter          git push triggers
    Templates auto-gen        Strip draft status            Cloudflare auto-build
    Private notes stay         npm run build check            ~2 min to live
    local                     git commit + push
```

---

## Vault Design

### Directory Layout

The first challenge: keeping writing files separate from project code. A blog root with `node_modules`, `src/`, `package.json`, etc. makes a messy Obsidian vault.

The solution: a dedicated vault subdirectory.

```
blog/                          ← Git repo root
├── obsidian content/          ← Obsidian vault (.gitignore)
│   ├── .obsidian/             ← Obsidian config
│   ├── _templates/            ← Article/note templates
│   ├── 文章/                  ← Draft articles
│   └── 笔记/                  ← Personal notes (not published)
├── src/content/
│   ├── blog-zh/               ← Published Chinese articles
│   ├── blog-en/               ← Published English articles
│   └── notes/                 ← Personal notes (not published)
├── publish-to-blog.ps1        ← One-click publish script
└── deploy.ps1                 ← Build + commit + push
```

### Why Exclude the Vault from Git?

The `obsidian content/` directory contains:

- **Personal notes** — not blog content
- **Draft articles** — unfinished work
- **Plugin binaries** — `main.js`, etc. shouldn't be in the repo
- **Workspace state** — `workspace.json`

So it's in `.gitignore`:

```
obsidian content/
```

Notes still sync to GitHub via the **Obsidian Git** plugin — just in a separate flow from the public blog repo.

---

## Template System

Obsidian's core **Templates** plugin auto-generates frontmatter from template files:

```yaml
---
title: "{{title}}"
description: "Brief description for SEO and article card display (max 120 chars)"
pubDate: 2026-05-03
tags: []
---
```

Key design decisions:

- **No `draft` field** — publish is publish. No forgotten draft status.
- **Placeholder description** — reminds you to fill it in, not an empty string.
- **Template variables** — `{{title}}` and `{{date:YYYY-MM-DD}}` get replaced on insert.

### Draft Handling Strategy

Instead of relying on `draft: true` in the template, the publish script auto-strips any `draft: true` it finds during the copy step. This means:

- You can still mark files as drafts in your vault
- Published articles are **always public**, no matter what

---

## One-Click Publishing Pipeline

The goal: **right-click a file in Obsidian → everything happens automatically**.

### Step 1: Shell Commands Plugin

**Obsidian Shell Commands** adds custom shell commands to the file context menu. Key features:

- **File menu event** — right-click integration
- **`{{event_file_path:absolute}}` variable** — captures the clicked file's path
- **Multiple shell types** — CMD, PowerShell, PowerShell Core

Configuration:

| Field | Value |
|-------|-------|
| Alias | Publish to Chinese Blog |
| Shell command | `powershell -File "D:\workspace\blog\publish-to-blog.ps1" -FilePath "{{event_file_path:absolute}}" -TargetLang zh` |
| Shell type | PowerShell |
| Events | ✅ File menu |

After setup, every `.md` file in the `文章/` folder has a "Publish to Chinese Blog" item in its right-click menu.

### Step 2: PowerShell Publish Script

`publish-to-blog.ps1` is the pipeline orchestrator:

```
Receive file path
    ↓
Validate frontmatter (title / description / pubDate required)
    ↓
Copy to src/content/blog-zh/
    ↓
Auto-remove draft: true
    ↓
Execute deploy.ps1 (npm run build → git commit → git push)
    ↓
Cloudflare auto-deploy
```

**Frontmatter validation** catches missing fields early:

```
[ERROR] Missing frontmatter: description, pubDate
```

**Auto-publication** strips `draft: true` from the copied file.

**Safety gate**: `npm run build` failure prevents broken pushes.

### Step 3: Deployment

`deploy.ps1` handles build verification and git operations:

```powershell
npm run build                    # Verify build
git add -A                       # Stage all changes
git commit -m "update: article"  # Commit
git push                         # Push → Cloudflare deploys
```

**One right-click. Everything else is automatic.**

---

## Pitfalls and Solutions

### 1. PowerShell `---` Parsing

Using strings containing `---` caused parser errors:

```powershell
# ✗ This fails
if ($content -match "^---\s*\n(.*?\n)---\s*\n") { ... }
```

PowerShell interprets `--` as the decrement operator. **Fix**: store the separator in a variable and use `StartsWith()`:

```powershell
$seperator = "---"
if (-not $content.StartsWith($seperator)) { ... }
```

### 2. Git on VHDX Filesystem

Running `git commit` inside a VHDX-based Linux sandbox corrupts the object store:

```
error: improper chunk offset(s)
```

**Root cause**: VHDX doesn't fully support Git's HardLink operations. **Fix**: execute all git commands in Windows PowerShell, not the Linux sandbox.

### 3. Obsidian Plugin Distribution

`community-plugins.json` can list required plugins, but `main.js` binaries can't be distributed through the repo (they're in `.gitignore`). **Fix**: clear installation instructions in the setup guide.

### 4. Astro Content Collection Warning

Adding a `notes/` directory under `src/content/` triggered:

```
Auto-generating collections for folders in "src/content/" that
are not defined as collections. This is deprecated.
```

**Fix**: define the notes collection in `src/content/config.ts`:

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

## The Final Workflow

### Writing

```
1. Open Obsidian, create file in 文章/
2. Ctrl+P → Templates: Insert template → new-post-en
3. Fill in title, description, body
```

### Publishing

```
4. Right-click → Publish to Chinese/English Blog
```

### Automation

```
5. Script validates frontmatter → copies to blog-zh/ or blog-en/
6. Auto-strips draft: true
7. npm run build verification
8. git commit + push
9. Cloudflare deploys (~2 minutes)
```

### Note-taking

```
1. Create file in 笔记/
2. Use new-note template
3. Write freely, use [[wikilinks]] for connections
4. Notes never appear on the blog
```

---

## Lessons Learned

The core philosophy: **eliminate friction through tool integration, not complexity**.

I deliberately avoided:

- Writing a custom Obsidian plugin (maintenance overhead)
- Adding a CI/CD platform (unnecessary complexity)
- Third-party publishing services (losing data ownership)

Instead, I leveraged:

- **Obsidian's plugin ecosystem** — Shell Commands for context menu integration
- **PowerShell scripting** — sufficient for file ops, validation, and git calls
- **GitHub + Cloudflare auto-deploy** — push-triggered, zero-ops deployment

The result: **write → right-click → wait 2 minutes → live**. No manual steps, no intermediate platforms.

---

*This article was published through the workflow described above.* 😄
