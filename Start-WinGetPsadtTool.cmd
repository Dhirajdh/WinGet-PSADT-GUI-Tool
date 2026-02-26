@echo off
setlocal
set "ROOT=%~dp0"
pushd "%ROOT%" >nul 2>&1

echo [WinGet-PSADT-GUI-Tool] Unblocking local project files...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Get-ChildItem -Path '%ROOT%' -Recurse -File -Include *.ps1,*.psm1,*.psd1,*.ps1xml,*.xaml,*.cmd | Unblock-File -ErrorAction SilentlyContinue } catch {}"

echo [WinGet-PSADT-GUI-Tool] Starting GUI...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -File "%ROOT%WinGet-PSADT-GUI.ps1"

set "EXITCODE=%ERRORLEVEL%"
popd >nul 2>&1
exit /b %EXITCODE%
