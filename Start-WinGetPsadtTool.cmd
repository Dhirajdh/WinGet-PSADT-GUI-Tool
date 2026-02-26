@echo off
setlocal

set "ROOT=%~dp0"

REM Unblock all files extracted from internet ZIP (best effort)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%ROOT%' -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue" >nul 2>&1

REM Start application in Windows PowerShell 5.1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%app\Start-WinGetPsadtTool.ps1"

endlocal
