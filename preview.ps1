﻿$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' }

if (-not $ips) {
  Write-Host ''
  Write-Host '没有找到可用的局域网地址。' -ForegroundColor Red
  Write-Host '请先确认电脑已连接 WiFi 或网线（或者已连上手机热点），然后关掉本窗口重新双击「手机预览.bat」。' -ForegroundColor Yellow
  Write-Host '如果地址是 169.254 开头，说明电脑当前没有真正连上网络。' -ForegroundColor Yellow
  Write-Host ''
}

foreach ($ip in $ips) {
  Write-Host ''
  Write-Host ('手机访问地址：http://' + $ip.IPAddress + ':8080/文图故事游戏.html') -ForegroundColor Green
  Write-Host ('（对应网络：' + $ip.InterfaceAlias + '）') -ForegroundColor DarkGray
}

Write-Host ''
Write-Host '热点用法：手机开热点让电脑连上，或电脑开热点让手机连上，再运行本脚本，用显示的地址访问。' -ForegroundColor Yellow
Write-Host '有多个地址时，选和手机同一网络的那个（一般 192.168. 或 172. 开头）。按 Ctrl+C 停止服务。' -ForegroundColor Yellow
Write-Host ''
python -m http.server 8080
