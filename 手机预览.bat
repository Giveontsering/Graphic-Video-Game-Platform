@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "preview.ps1"
pause
