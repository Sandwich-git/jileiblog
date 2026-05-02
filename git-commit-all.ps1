<#
.SYNOPSIS
  一键提交所有待推送变更（Obsidian 集成 + 文章改动）
  在 Windows PowerShell 中运行，避免 VHDX 兼容性问题
#>

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host "===== jilei.blog 一键提交 =====" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 git 状态
Write-Host "[1/4] 检查仓库状态..." -ForegroundColor Yellow
git status --short
Write-Host ""

# 2. 修复可能的索引损坏
Write-Host "[2/4] 修复 git 索引（如有必要）..." -ForegroundColor Yellow
$hasError = git status 2>&1 | Select-String -Pattern "improper chunk|error:"
if ($hasError) {
    Write-Host "  检测到索引损坏，重建中..." -ForegroundColor Gray
    if (Test-Path ".git\index") { Remove-Item ".git\index" -Force }
    git reset HEAD -- . 2>$null
    Write-Host "  索引已修复。" -ForegroundColor Green
} else {
    Write-Host "  索引正常。" -ForegroundColor Green
}
Write-Host ""

# 3. 添加全部变更并提交
Write-Host "[3/4] 提交变更..." -ForegroundColor Yellow
git add -A
git commit -m "feat: add Obsidian integration (config, templates, setup guide)"
if ($LASTEXITCODE -eq 0) {
    Write-Host "  提交成功。" -ForegroundColor Green
} else {
    Write-Host "  没有新的变更需要提交。" -ForegroundColor Gray
}
Write-Host ""

# 4. 推送
Write-Host "[4/4] 推送到 GitHub..." -ForegroundColor Yellow
git push
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "===== 全部完成！=====" -ForegroundColor Green
    Write-Host "Cloudflare 将自动部署。" -ForegroundColor Cyan
}
