function Publish-WGPTIntuneApp {
<#!
.SYNOPSIS
Compatibility wrapper for Intune upload.
.PARAMETER IntuneWinPath
Path to intunewin file.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [ValidatePattern('\.intunewin$')]
        [string]$IntuneWinPath
    )

    Invoke-WGPTLegacyIntuneUpload -IntuneWinPath $IntuneWinPath
}
