function Ensure-PSADTModule {
    # Only ensure module presence; avoid importing in this runspace to prevent TypeData collisions.
    Write-DebugLog "INFO" "EnsurePSADTModuleStart"
    if (-not (Get-Module -ListAvailable -Name PSAppDeployToolkit.Tools -ErrorAction SilentlyContinue)) {
        Write-DebugLog "WARN" "PSAppDeployToolkit.Tools not found in ListAvailable; prompting install."
        $r = Show-Msg(
            "PSAppDeployToolkit.Tools module not found.`n`nInstall it now from PSGallery?",
            "Module Missing",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($r -ne "Yes") {
            Write-DebugLog "WARN" "PSADT module install declined by user."
            return $false
        }
        Set-Status "Installing PSAppDeployToolkit.Tools..." "#3B82F6"
        try {
            Install-Module PSAppDeployToolkit.Tools -Scope CurrentUser -Force -ErrorAction Stop
            Write-DebugLog "INFO" "PSADT module installed successfully."
        } catch {
            Write-DebugLog "ERROR" ("PSADT module install failed: {0}" -f $_.Exception.Message)
            Show-Msg("Install failed:`n`n$($_.Exception.Message)","Error",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
            return $false
        }
    }
    Write-DebugLog "INFO" "EnsurePSADTModuleEnd | Result=True"
    return $true
}

