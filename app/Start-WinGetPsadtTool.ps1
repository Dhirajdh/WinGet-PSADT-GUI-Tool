#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\src\WinGetPsadtTool\WinGetPsadtTool.psd1'
Import-Module (Resolve-Path $modulePath) -Force
Start-WGPTGui
