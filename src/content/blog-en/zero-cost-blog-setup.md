---
title: "Building a Zero-Cost Tech Blog — Astro + Cloudflare Pages Guide"
description: "A complete walkthrough of setting up jilei.blog with Astro, GitHub, and Cloudflare Pages, including all the pitfalls encountered along the way."
pubDate: 2026-05-02
tags: ["Blog", "Astro", "Cloudflare", "Tutorial"]
---

# Building a Zero-Cost Tech Blog

## Why This Blog

I wanted a personal tech blog to share tips and solutions for using Claude effectively. My requirements were:

- **Near-zero cost** — No monthly hosting fees
- **Full content ownership** — Not locked into any platform
- **Chinese reader friendly** — Must work well behind the Great Firewall
- **Modern tech stack** — Fun to build and maintain

After evaluating options, I settled on **Astro + GitHub + Cloudflare Pages**. This article documents the entire setup process.

---

## Tech Stack

| Component | Choice | Cost |
|-----------|--------|------|
| Framework | Astro 5 | Free |
| Styling | Tailwind CSS 4 | Free |
| Hosting | Cloudflare Pages | Free |
| Version Control | GitHub | Free |
| Comments | Giscus (via GitHub Discussions) | Free |
| Domain | jilei.blog | ¥59/year (~$8) |
| **Total** | | **¥59/year** |

The architecture is straightforward:

```
Local Markdown → Git Push → Cloudflare Build → Global CDN
```

No server, no database, no DevOps overhead.

---

## Key Challenges

### Cross-Platform File Issues

The project was scaffolded in a Linux sandbox and copied to Windows. The biggest pain point: **esbuild binaries are platform-specific**. After copying, the Windows build failed with an `EFTYPE` error.

**Fix**: Delete `node_modules` and reinstall. esbuild downloads the correct platform binary automatically.

### Giscus & The Great Firewall

Giscus (the comment system) loads from `giscus.app`, which is blocked in China without a VPN:

```
Failed to load resource: net::ERR_CONNECTION_RESET
```

Even with a VPN, Giscus initially didn't render because:

1. `document.currentScript` failed in Astro's optimized build output
2. Astro's build process stripped `<script is:inline>` from the component

**Fixes**: Use `getElementById` instead of `currentScript`; switch from Astro's `is:inline` to plain `<script>` tags.

### Git Housekeeping

The `.gitignore` was lost during file transfer, causing `node_modules` to be tracked. This produced hundreds of LF→CRLF warnings on Windows.

**Fix**: Recreate `.gitignore`, then `git rm -r --cached node_modules` to untrack.

---

## Cost Breakdown

| Item | Cost | Notes |
|------|------|-------|
| Domain (jilei.blog) | ¥59/year | |
| Cloudflare Pages | Free | Unlimited bandwidth, auto HTTPS |
| GitHub | Free | Public repo required for Giscus |
| Astro + Tailwind | Free | Open source |
| Giscus comments | Free | Powered by GitHub Discussions |
| **Year 1 Total** | **¥59** | Same for renewal |

---

## Lessons Learned

1. **Use your real name as domain** — It builds personal brand over time
2. **Astro is excellent for content sites** — Fast builds, great DX, plays well with LLM-assisted coding
3. **Cloudflare Pages free tier is generous** — Unlimited bandwidth for personal blogs
4. **Markdown = freedom** — Your content is portable, never locked in
5. **Every bug is future content** — Each issue you solve becomes a blog post

The blog is live now at [jilei.blog](https://jilei.blog). Future posts will cover Claude tips, AI workflows, and more technical deep dives. Comments are welcome — though you might need a VPN to see the comment section if you're in China.
