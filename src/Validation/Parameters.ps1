function Resolve-WingetPackageVersion([string]$PackageId,[string]$GridVersion) {
    $candidate = ""
    if (![string]::IsNullOrWhiteSpace($GridVersion) -and $GridVersion -match '\d+(\.\d+)+([-\w\.]*)?') {
        $candidate = $Matches[0]
    }
    $winget = Get-WingetPath
    if (!$winget -or [string]::IsNullOrWhiteSpace($PackageId)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { return "UnknownVersion" }
        return $candidate
    }
    try {
        $show = & $winget show --id "$PackageId" --exact --source winget --accept-source-agreements --disable-interactivity 2>&1
        foreach ($line in $show) {
            $clean = ($line -replace "\x1b\[[0-9;]*[A-Za-z]","" -replace "[^\x20-\x7E]","").Trim()
            if ($clean -match '^Version\s*:\s*(.+)$') {
                $ver = $Matches[1].Trim()
                if ($ver -match '\d') { return $ver }
            }
        }
    } catch {}
    if ([string]::IsNullOrWhiteSpace($candidate)) { return "UnknownVersion" }
    return $candidate
}

function Resolve-BestAppVersion([object]$SelectedItem,[object]$Context) {
    $isValidVersion = {
        param($v)
        if ([string]::IsNullOrWhiteSpace([string]$v)) { return $false }
        $s = [string]$v
        if ($s -eq "N/A" -or $s -eq "UnknownVersion" -or $s -eq "1.0.0") { return $false }
        return ($s -match '\d')
    }
    if (& $isValidVersion $Global:SelectedVersion) { return [string]$Global:SelectedVersion }

    try {
        if ($Context -and $Context.ScriptPath -and (Test-Path $Context.ScriptPath)) {
            $d = Get-AppDetailsFromScript -ScriptPath $Context.ScriptPath -AppName $Context.AppName -Version ""
            if ($d -and (& $isValidVersion $d.AppVersion)) { return [string]$d.AppVersion }
        }
    } catch {}

    if ($SelectedItem) {
        $id = if ($SelectedItem.ID) { [string]$SelectedItem.ID } else { "" }
        $gridVer = if ($SelectedItem.Version) { [string]$SelectedItem.Version } else { "" }
        $wv = Resolve-WingetPackageVersion -PackageId $id -GridVersion $gridVer
        if (& $isValidVersion $wv) { return [string]$wv }
    }

    try {
        if ($Context -and $Context.Installer -and (Test-Path $Context.Installer.FullName)) {
            $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Context.Installer.FullName)
            foreach ($pv in @($vi.ProductVersion,$vi.FileVersion)) {
                if (& $isValidVersion $pv) { return [string]$pv }
            }
        }
    } catch {}

    if (& $isValidVersion $Global:SelectedVersion) { return [string]$Global:SelectedVersion }
    return "UnknownVersion"
}

