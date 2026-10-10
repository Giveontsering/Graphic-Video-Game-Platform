# 文图故事游戏 - 内容更新脚本
# 作用：扫描 story 文件夹里的 .md 文本，自动生成游戏数据 story_data.js
# 用法：双击「更新游戏.bat」，或手动运行  powershell -File build.ps1
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$storyDir = Join-Path $root 'story'
$assetsDir = Join-Path $root 'assets'
$outFile = Join-Path $root 'story_data.js'

if (-not (Test-Path $storyDir)) {
    Write-Host '找不到 story 文件夹，请在游戏目录下新建 story 文件夹并放入 .md 文本。' -ForegroundColor Red
    exit 1
}

# 收集所有节点 id（文件名 = 节点 id）
$ids = @{}
Get-ChildItem -Path $storyDir -Filter *.md | ForEach-Object { $ids[$_.BaseName] = $true }

# 转义为 JS 字符串
function Escape-Js([string]$s) {
    if ($null -eq $s) { return '""' }
    $s = $s -replace '\\', '\\\\'
    $s = $s -replace '"', '\"'
    $s = $s -replace "`r`n", '\n'
    $s = $s -replace "`r", '\n'
    $s = $s -replace "`n", '\n'
    $s = $s -replace "`t", '\t'
    return '"' + $s + '"'
}

$nodes = @()
$warnings = @()

Get-ChildItem -Path $storyDir -Filter *.md | Sort-Object Name | ForEach-Object {
    $file = $_
    $raw = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $lines = $raw -split "`r?`n"

    $node = @{ id = $file.BaseName; title = ''; img = ''; text = @(); choices = @() }

    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t -eq '') { continue }
        if ($t -match '^#\s+(.+)$')       { $node.title = $Matches[1].Trim(); continue }
        if ($t -match '^图片\s*[:：]\s*(.+)$') { $node.img = $Matches[1].Trim(); continue }
        if ($t -match '^\[(.+)\]\s*->\s*(\S+)\s*$') {
            $node.choices += @{ label = $Matches[1].Trim(); target = $Matches[2] }
            continue
        }
        $node.text += $t
    }

    if ($node.title -eq '') {
        $warnings += "「$($node.id)」没有标题：请在文件第一行写「# 标题」。"
    }
    if ($node.text.Count -eq 0) {
        $warnings += "「$($node.id)」没有正文内容。"
    }
    # 没写「图片:」时，自动匹配 assets 下与节点同名的图片/视频
    if ($node.img -eq '') {
        foreach ($ext in @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.mp4', '.webm', '.mov')) {
            $cand = Join-Path $assetsDir ($node.id + $ext)
            if (Test-Path $cand) { $node.img = $node.id + $ext; break }
        }
    }
    if ($node.img -ne '' -and -not (Test-Path (Join-Path $assetsDir $node.img))) {
        $warnings += "「$($node.id)」引用的图片 assets\$($node.img) 不存在。"
    }
    foreach ($c in $node.choices) {
        if (-not $ids.ContainsKey($c.target)) {
            $warnings += "「$($node.id)」的分支 [$($c.label)] 指向不存在的节点「$($c.target)」：请先新建 story\$($c.target).md。"
        }
    }

    $nodes += $node
}

if ($nodes.Count -eq 0) {
    Write-Host 'story 文件夹里没有找到任何 .md 文件。' -ForegroundColor Red
    exit 1
}
if (-not ($ids.ContainsKey('start') -or $ids.ContainsKey('序章'))) {
    Write-Host '缺少起始节点：请新建 story\start.md 或 story\序章.md（游戏从它开始）。' -ForegroundColor Red
    exit 1
}

# 生成 story_data.js
$parts = foreach ($n in $nodes) {
    $texts = ($n.text | ForEach-Object { Escape-Js $_ }) -join ','
    $choices = ($n.choices | ForEach-Object { '{label:' + (Escape-Js $_.label) + ',target:' + (Escape-Js $_.target) + '}' }) -join ','
    '{id:' + (Escape-Js $n.id) + ',title:' + (Escape-Js $n.title) + ',img:' + (Escape-Js $n.img) + ',text:[' + $texts + '],choices:[' + $choices + ']}'
}
$js = "window.STORY_DATA = [`r`n" + ($parts -join ",`r`n") + "`r`n];`r`n"
[System.IO.File]::WriteAllText($outFile, $js, (New-Object System.Text.UTF8Encoding $true))

Write-Host ('更新完成：共生成 ' + $nodes.Count + ' 个节点。' -f $nodes.Count) -ForegroundColor Green
Write-Host ('数据文件：' + $outFile) -ForegroundColor Green

if ($warnings.Count -gt 0) {
    Write-Host ''
    Write-Host ('发现 ' + $warnings.Count + ' 条需要注意的问题：') -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host ('  - ' + $_) -ForegroundColor Yellow }
}
