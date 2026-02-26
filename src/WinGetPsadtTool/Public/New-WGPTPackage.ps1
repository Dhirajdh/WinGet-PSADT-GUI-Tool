function New-WGPTPackage {
<#!
.SYNOPSIS
Compatibility wrapper for package creation.
.PARAMETER AppName
Application display name.
.PARAMETER PackageId
WinGet package id.
.PARAMETER Version
Application version.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$AppName,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$PackageId,
        [Parameter(Mandatory)][ValidatePattern('^[0-9A-Za-z._+-]+$')][string]$Version
    )

    Invoke-WGPTLegacyPackaging -AppName $AppName -PackageId $PackageId -Version $Version
}
