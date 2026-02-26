function Invoke-WGPTLegacyPackaging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$AppName,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$PackageId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Version
    )

    Write-WGPTLog -Level Info -Message "Compatibility mode packaging request: $AppName [$PackageId] $Version"
    throw 'Direct headless packaging entrypoint is not yet separated from legacy GUI flow. Use Start-WGPTGui.'
}
