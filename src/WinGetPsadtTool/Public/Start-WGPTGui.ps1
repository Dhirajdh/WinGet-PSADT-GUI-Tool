function Start-WGPTGui {
<#!
.SYNOPSIS
Starts the WinGet-PSADT GUI tool.
.DESCRIPTION
Initializes module logging and validations, then launches the existing GUI script in compatibility mode.
.EXAMPLE
Start-WGPTGui
#>
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Stop'
    Initialize-WGPTLogging
    Assert-WGPTPrerequisites
    Start-WGPTGuiHost
}
