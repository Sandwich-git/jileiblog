<#
.SYNOPSIS
  新建文章 — 自动生成带 frontmatter 的 Markdown 文件
.PARAMETER Title
  文章标题（必填）
.PARAMETER Lang
  语言：zh（中文，默认）或 en（英文）
.PARAMETER Description
  文章简介（可选，不填则留空）
.PARAMETER Tags
  标签，多个用逗号分隔（可选）
.PARAMETER Edit
  生成后自动用 VS Code 打开
.EXAMPLE
  .\new-post.ps1 -Title "如何高效使用 Claude" -Tags "Claude,教程" -Edit
  .\new-post.ps1 -Title "Getting Started with Claude" -Lang en -Description "A beginner's guide"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [ValidateSet("zh", "en")]
    [string]$Lang = "zh",

    [string]$Description = "",

    [string]$Tags = "",

    [switch]$Edit
)

# 生成 slug：中文转拼音？不需要，直接用英文/拼音做文件名
$slug = $Title.ToLower() -replace '[^\w\s-]', '' -replace '\s+', '-' -replace '-+', '-' -replace '^-|-$', ''
if ($slug -eq '') { $slug = "post-$(Get-Date -Format 'yyyyMMdd')" }

$date = Get-Date -Format 'yyyy-MM-dd'
$dir = if ($Lang -eq "en") { "src/content/blog-en" } else { "src/content/blog-zh" }
$filename = "$dir\$slug.md"

# 保证目录存在
New-Item -ItemType Directory -Path $dir -Force | Out-Null

# 处理标签
$tagsYaml = if ($Tags) {
    ($Tags -split ',' | ForEach-Object { "  - ""$($_.Trim())""" }) -join "`n"
} else {
    "  []"
}

$content = @"---
title: "$Title"
description: "$Description"
pubDate: $date
tags:
$tagsYaml
draft: true
---

# $Title


"@

# 写入文件（UTF-8 without BOM）
[System.IO.File]::WriteAllText("$PWD\$filename", $content)

Write-Host "✅ 文章已创建：" -ForegroundColor Green
Write-Host "   $filename" -ForegroundColor Blue

if ($Edit) {
    code "$filename"
}
else {
    Write-Host "💡 用 '$code $filename' 打开编辑" -ForegroundColor Gray
}
