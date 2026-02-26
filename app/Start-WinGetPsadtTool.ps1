#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Best-effort unblock to avoid repetitive MOTW security prompts on ZIP downloads.
try {
    Get-ChildItem -Path $repoRoot -Recurse -File -ErrorAction SilentlyContinue |
        Unblock-File -ErrorAction SilentlyContinue
}
catch {
    # Non-fatal: continue even if some files cannot be unblocked.
}

$modulePath = Join-Path $PSScriptRoot '..\src\WinGetPsadtTool\WinGetPsadtTool.psd1'
Import-Module (Resolve-Path $modulePath) -Force
Start-WGPTGui
