function Invoke-WGPTLegacyIntuneUpload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$IntuneWinPath
    )

    Write-WGPTLog -Level Info -Message "Compatibility mode upload request: $IntuneWinPath"
    throw 'Direct headless upload entrypoint is not yet separated from legacy GUI flow. Use Start-WGPTGui.'
}
