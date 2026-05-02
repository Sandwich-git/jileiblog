<#
.SYNOPSIS
  一键部署 — 构建检查、提交推送、查询部署状态
.DESCRIPTION
  1. npm run build 检查
  2. git 提交 + 推送
  3. 查询 Cloudflare 部署进度（需配置 CF_ACCOUNT_ID / CF_API_TOKEN）
#>

$ErrorActionPreference = "Stop"

# ---- 1. 构建检查 ----
Write-Host "Build check..." -ForegroundColor Cyan
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "BUILD FAILED. Fix errors and retry." -ForegroundColor Red
    exit 1
}
Write-Host "Build passed." -ForegroundColor Green

# ---- 2. 提交 ----
$changed = git status --porcelain | Where-Object { $_ -match '\.md$' } | ForEach-Object {
    $_.Substring(3).Replace('"', '')
}

$time = Get-Date -Format 'yyyy-MM-dd HH:mm'

if ($changed.Count -gt 0) {
    $articles = ($changed | ForEach-Object { $_ -replace '^src/content/blog-[\w-]+/', '' -replace '\.md$', '' }) -join ', '
    $msg = "update: $articles — $time"
} else {
    $msg = "update: $time"
}

git add -A
git commit -m $msg

# ---- 3. 推送 ----
Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git push
Write-Host "Pushed. Cloudflare is deploying." -ForegroundColor Green

# ---- 4. 查询部署状态（可选） ----
$accountId = $env:CF_ACCOUNT_ID
$apiToken = $env:CF_API_TOKEN

if ($accountId -and $apiToken) {
    Write-Host "Waiting for Cloudflare deploy..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5

    $url = "https://api.cloudflare.com/client/v4/accounts/$accountId/pages/projects/jileiblog/deployments?per_page=1"
    $headers = @{
        "Authorization" = "Bearer $apiToken"
        "Content-Type"  = "application/json"
    }

    try {
        for ($i = 0; $i -lt 18; $i++) {
            $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
            $deploy = $resp.result[0]

            if (-not $deploy) {
                Write-Host "  Waiting for deploy to start..." -ForegroundColor Gray
                Start-Sleep -Seconds 10
                continue
            }

            $stage = $deploy.stages | Where-Object { $_.name -eq "deploy" }
            $buildStage = $deploy.stages | Where-Object { $_.name -eq "build" }

            $status = if ($stage) { $stage.status } else { $buildStage.status }

            if ($status -eq "success") {
                $deployUrl = $deploy.url
                Write-Host "SUCCESS!   $deployUrl" -ForegroundColor Green
                return
            }
            elseif ($status -eq "failure") {
                Write-Host "FAILED. Check Cloudflare Dashboard." -ForegroundColor Red
                return
            }
            else {
                $elapsed = ($i + 1) * 10
                Write-Host "  Deploying... (${elapsed}s)" -ForegroundColor Gray
                Start-Sleep -Seconds 10
            }
        }
        Write-Host "Deploy still running. Check Cloudflare Dashboard." -ForegroundColor Yellow
    }
    catch {
        Write-Host "Cannot check deploy status. Check Cloudflare Dashboard." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Check deploy at: https://dash.cloudflare.com/?to=/:account/pages/view/jileiblog" -ForegroundColor Blue
    Write-Host "Set CF_ACCOUNT_ID and CF_API_TOKEN to see progress here." -ForegroundColor Gray
}
