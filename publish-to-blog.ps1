<#
.SYNOPSIS
  Publish Obsidian article to blog and trigger deployment
.DESCRIPTION
  Usage (called by Obsidian Shell Commands):
    powershell -File "D:\workspace\blog\publish-to-blog.ps1" -FilePath "path\to\article.md" -TargetLang zh
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $false)]
    [ValidateSet("zh", "en")]
    [string]$TargetLang = "zh"
)

$ErrorActionPreference = "Stop"
$BlogRoot = "D:\workspace\blog"

# ---- 1. Determine target ----
if ($TargetLang -eq "zh") {
    $TargetDir = "$BlogRoot\src\content\blog-zh"
    $LangLabel = "中文博客"
} else {
    $TargetDir = "$BlogRoot\src\content\blog-en"
    $LangLabel = "英文博客"
}

# ---- 2. Validate file ----
if (-not (Test-Path $FilePath)) {
    Write-Host "[ERROR] File not found: $FilePath" -ForegroundColor Red
    exit 1
}

$Filename = [System.IO.Path]::GetFileName($FilePath)
$TargetFile = Join-Path $TargetDir $Filename

# ---- 3. Parse frontmatter ----
$seperator = "---"
$content = Get-Content $FilePath -Raw

# Check if file starts with "---"
if (-not $content.StartsWith($seperator)) {
    Write-Host "[ERROR] No frontmatter found!" -ForegroundColor Red
    Write-Host "Add this at the top of your file:" -ForegroundColor Yellow
    Write-Host $seperator -ForegroundColor Cyan
    Write-Host 'title: "'"$Filename"'"' -ForegroundColor Cyan
    Write-Host 'description: "文章简介"' -ForegroundColor Cyan
    Write-Host "pubDate: $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Cyan
    Write-Host "tags: []" -ForegroundColor Cyan
    Write-Host "draft: true" -ForegroundColor Cyan
    Write-Host $seperator -ForegroundColor Cyan
    exit 1
}

# Split frontmatter from body
$parts = $content -split "`n$seperator`n"
if ($parts.Count -lt 2) {
    $parts = $content -split "`r`n$seperator`r`n"
}
if ($parts.Count -lt 2) {
    # Try splitting on "---" at line boundaries
    $lines = $content -split "`n"
    if ($lines[0] -eq $seperator) {
        $endIndex = -1
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq $seperator) {
                $endIndex = $i
                break
            }
        }
        if ($endIndex -gt 0) {
            $frontmatterLines = $lines[1..($endIndex - 1)]
            $fmText = $frontmatterLines -join "`n"

            # Check required fields
            $missing = @()
            $hasTitle = $false
            $hasDesc = $false
            $hasDate = $false
            foreach ($ln in $frontmatterLines) {
                if ($ln -match '^title:\s*\S') { $hasTitle = $true }
                if ($ln -match '^description:\s*\S') { $hasDesc = $true }
                if ($ln -match '^pubDate:\s*\S') { $hasDate = $true }
            }
            if (-not $hasTitle) { $missing += "title" }
            if (-not $hasDesc) { $missing += "description" }
            if (-not $hasDate) { $missing += "pubDate" }

            if ($missing.Count -gt 0) {
                Write-Host "[ERROR] Missing frontmatter: $($missing -join ', ')" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "[ERROR] Frontmatter not closed (missing closing '---')" -ForegroundColor Red
            exit 1
        }
    }
}

# ---- 4. Copy file ----
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
Copy-Item $FilePath $TargetFile -Force
Write-Host "[OK] Copied: $Filename -> blog-$TargetLang" -ForegroundColor Green

# ---- 5. Check draft status ----
if ($content -match "draft:\s*true") {
    Write-Host "[Note] Article is draft:true, won't show on blog" -ForegroundColor Yellow
}

# ---- 6. Run deploy ----
Write-Host ""
Write-Host "Now deploying..." -ForegroundColor Cyan

$deployScript = "$BlogRoot\deploy.ps1"
if (Test-Path $deployScript) {
    Push-Location $BlogRoot
    & $deployScript
    Pop-Location
} else {
    Write-Host "[!] deploy.ps1 not found" -ForegroundColor Yellow
}
