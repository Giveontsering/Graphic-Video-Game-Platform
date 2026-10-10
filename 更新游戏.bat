@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "build.ps1"
echo.
echo 数据已更新。现在可以打开或刷新「文图故事游戏.html」开始玩。
pause
