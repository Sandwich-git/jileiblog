---
title: "What It's Like to Blog with Claude Code? A Real Human-AI Collaboration Log"
description: "From homepage visual design to video processing and search debugging — a real record of Claude Code human-AI collaboration, with 7 productivity tips."
pubDate: 2026-05-04
tags: ["Claude-Code", "AI-Programming", "Human-AI-Collaboration", "Astro"]
---

I recently rebuilt my blog's homepage with Claude Code — visual design, video processing, search debugging, all done through human-AI collaboration. This post skips the abstract concepts and goes straight into what we actually did and how we worked together.

## Why Claude Code

My old blog workflow was: write code locally → commit → wait for Cloudflare Pages to build before seeing results. A simple style tweak took at least 5 minutes per cycle.

Claude Code runs `npm run dev` right in the terminal. I change requirements, it changes code, dev server hot-reloads instantly. **The feedback loop went from minutes to seconds.** Plus, it reads and writes my project files directly — no pasting code snippets into a chat window and waiting for replies.

## A few memorable collaboration moments

### 1. Video processing: solved in one sentence

I wanted a close-up wolf video as the homepage background. Raw footage was 24MB. I just said:

> "24MB video, compress it and make it loop"

It handled everything with FFmpeg: trimmed to an 8-second loop, compressed to 560KB (WebM) + 1.85MB (MP4 fallback) with VP9 encoding, generated a poster image, and implemented `requestIdleCallback` lazy loading to avoid blocking first paint.

Doing this myself would have meant researching FFmpeg parameters, studying video format compatibility, writing lazy loading logic from scratch — at least 30 minutes.

### 2. Give it a reference, get back a working implementation

I wanted the hero card to have a visionOS-like Liquid Glass feel. I dropped a reference article link.

It understood the core CSS techniques from the article (dual-layer shimmer reflections, amber refraction light, window-frame highlight lines) and adapted them to my existing components. I could see the result instantly with `npm run dev`. We eventually reverted to the original transparent glass style due to personal preference, but **the ability to experiment and roll back** was incredibly valuable — if I'd have to spend 30 minutes implementing something before deciding I don't like it, I probably wouldn't have tried at all.

### 3. You spot the symptom, it finds the root cause

Search returned 404s after launch. I said "search is broken." It checked the build logs, looked up Pagefind docs, analyzed my Astro config, and within minutes found the root cause: Pagefind generates output in `dist/pagefind/`, but `astro dev` only serves `public/`.

The fix was clean: add one `cpSync` line to the `package.json` build script, automatically copying `dist/pagefind/` to `public/pagefind/` after each build. Then add `public/pagefind/` to `.gitignore`.

This **"human spots anomaly → AI traces root cause → both confirm the fix → AI implements it"** pattern is way more efficient than digging through Stack Overflow alone.

### 4. Building a dark mode system from scratch

Setting up Tailwind CSS 4 dark mode involved: a custom forest color palette (9 CSS variables), `@custom-variant` class-based toggling, and `localStorage` persistence. I just said "use dark mode by default," and it wired everything together — global CSS, layout components, Header adapters, separate light/dark style overrides.

Several edge cases came up: invisible header text in light mode, the white background box clashing with the dark theme, jarring header colors on article pages. For each one, I described the symptom, it located and fixed the issue — averaging two to three minutes per fix.

## Seven collaboration tips

Looking back, here are seven practices that made this collaboration more effective:

1. **Share a reference link instead of hunting for adjectives**: Saying "I want Liquid Glass" is vague; dropping an Apple design link is precise
2. **Describe constraints, not implementations**: Say "preserve SEO, don't block loading," and it will pick `requestIdleCallback` on its own — telling it exactly which API to use just limits what's possible
3. **Iterate fast, revert when needed**: See results in dev server within seconds, commit each round, revert if it doesn't work
4. **Let AI execute, not just advise**: Say "compress this video" rather than "what's the FFmpeg command" — skip the copy-paste step
5. **Embrace full project context**: Claude Code reads all your files, so you don't need to spend 10 minutes explaining your project structure
6. **Git is your safety net**: Experiment boldly, revert freely — this mindset makes exploration much more productive
7. **Human spots the symptom, AI traces the root cause**: You're best at saying "this looks wrong," it's best at tracing code paths to find out why

## It's not replacement, it's acceleration

Claude Code didn't make decisions for me — visual direction, design choices, release timing — all mine. What it solved is: **turning ideas into something visible, testable, and changeable, several times faster.**

Changing a homepage style used to take 15+ minutes of browsing docs, editing, and verifying. Now it's one sentence plus a few seconds of hot reload. The time saved goes into thinking about what actually matters: what to write and whether the experience is good.

I'm maintaining this blog with this workflow now. More posts to come.
