# 一键部署脚本 — 自动提交并推送文章改动

# 获取改动的 .md 文件列表
$changed = git status --porcelain | Where-Object { $_ -match '\.md$' } | ForEach-Object {
    # 提取文件名（去掉状态前缀如 " M " 或 "?? "）
    $_.Substring(3).Replace('"', '')
}

$time = Get-Date -Format 'yyyy-MM-dd HH:mm'

if ($changed.Count -gt 0) {
    # 用文章名拼接提交信息
    $articles = ($changed | ForEach-Object { $_ -replace '^src/content/blog-[\w-]+/', '' -replace '\.md$', '' }) -join ', '
    $msg = "update: $articles — $time"
} else {
    $msg = "update: $time"
}

git add -A
git commit -m $msg
git push
