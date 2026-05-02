<#
.SYNOPSIS
  Publish Obsidian article to blog and trigger deployment
.DESCRIPTION
  Usage (called by Obsidian Shell Commands):
    powershell -File "D:\workspace\blog\publish-to-blog.ps1" -FilePath "path\to\article.md"
  Parameters:
    -FilePath   Absolute path to the markdown file in Obsidian vault
    -TargetLang "zh" for Chinese blog, "en" for English blog (default: zh)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $false)]
    [string]$TargetLang = "zh"
)

$ErrorActionPreference = "Stop"
$BlogRoot = "D:\workspace\blog"

# ---- 1. Determine target ----
if ($TargetLang -eq "zh") {
    $TargetDir = Join-Path $BlogRoot "src\content\blog-zh"
    $LangLabel = "中文博客"
} else {
    $TargetDir = Join-Path $BlogRoot "src\content\blog-en"
    $LangLabel = "英文博客"
}

# ---- 2. Validate & copy ----
if (-not (Test-Path $FilePath)) {
    Write-Host "[ERROR] File not found: $FilePath" -ForegroundColor Red
    exit 1
}

$Filename = [System.IO.Path]::GetFileName($FilePath)
$TargetFile = Join-Path $TargetDir $Filename

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

Copy-Item $FilePath $TargetFile -Force

Write-Host "[OK] Copied $Filename  ->  src\content\blog-$TargetLang\" -ForegroundColor Green

# ---- 3. Check draft ----
$content = Get-Content $TargetFile -Raw
if ($content -match "draft:\s*true") {
    Write-Host "[!] Note: article is still draft:true, won't appear in blog listing" -ForegroundColor Yellow
}

# ---- 4. Run deploy ----
Write-Host ""
Write-Host ">>> Deploying..." -ForegroundColor Cyan
Write-Host ""

$deployScript = Join-Path $BlogRoot "deploy.ps1"
if (Test-Path $deployScript) {
    Push-Location $BlogRoot
    & $deployScript
    Pop-Location
} else {
    Write-Host "[!] deploy.ps1 not found, skipping deploy" -ForegroundColor Yellow
}
