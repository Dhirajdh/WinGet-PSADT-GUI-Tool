function Start-WGPTGuiHost {
    [CmdletBinding()]
    param()

    Write-WGPTLog -Level Info -Message 'Launching legacy GUI host script in compatibility mode.'
    Invoke-WGPTLegacyScript
}
