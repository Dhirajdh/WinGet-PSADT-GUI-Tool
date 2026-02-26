function Get-WingetPackageInfo([string]$PackageId) {
    $out = [PSCustomObject]@{
        Version        = ""
        Publisher      = ""
        InformationUrl = ""
        PrivacyUrl     = ""
        Developer      = ""
        Owner          = ""
        Notes          = ""
    }
    if ([string]::IsNullOrWhiteSpace($PackageId)) { return $out }
    $winget = Get-WingetPath
    if (!$winget) { return $out }
    try {
        $lines = & $winget show --id "$PackageId" --exact --source winget --accept-source-agreements --disable-interactivity 2>&1 |
            ForEach-Object { ($_ -replace "\x1b\[[0-9;]*[A-Za-z]","" -replace "[^\x20-\x7E]","").Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        foreach ($ln in $lines) {
            if ($ln -notmatch "^\s*([^:]+)\s*:\s*(.*)$") { continue }
            $k = ($Matches[1]).Trim().ToLowerInvariant()
            $v = ($Matches[2]).Trim()
            if ([string]::IsNullOrWhiteSpace($v)) { continue }
            if ($k -eq "version" -and [string]::IsNullOrWhiteSpace($out.Version)) { $out.Version = $v; continue }
            if ($k -eq "publisher" -and [string]::IsNullOrWhiteSpace($out.Publisher)) { $out.Publisher = $v; continue }
            if (($k -match "homepage|url|package url|information url") -and [string]::IsNullOrWhiteSpace($out.InformationUrl)) { $out.InformationUrl = $v; continue }
            if (($k -match "privacy") -and [string]::IsNullOrWhiteSpace($out.PrivacyUrl)) { $out.PrivacyUrl = $v; continue }
            if (($k -match "author|developer") -and [string]::IsNullOrWhiteSpace($out.Developer)) { $out.Developer = $v; continue }
            if (($k -match "description|short description") -and [string]::IsNullOrWhiteSpace($out.Notes)) { $out.Notes = $v; continue }
        }
        if ([string]::IsNullOrWhiteSpace($out.Developer) -and $out.Publisher) { $out.Developer = $out.Publisher }
        if ([string]::IsNullOrWhiteSpace($out.Owner) -and $out.Publisher) { $out.Owner = $out.Publisher }
    } catch {}
    return $out
}

function Find-DownloadedInstaller([string]$FilesFolder) {
    if ([string]::IsNullOrWhiteSpace($FilesFolder) -or !(Test-Path $FilesFolder)) { return $null }

    $all = Get-ChildItem -Path $FilesFolder -Recurse -File -ErrorAction SilentlyContinue
    if (!$all) { return $null }

    $preferredExt = @(".exe",".msi",".msp",".msix",".appx",".msixbundle",".appxbundle")
    $preferred = $all | Where-Object { $preferredExt -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object LastWriteTime -Descending
    if ($preferred) { return $preferred | Select-Object -First 1 }

    # Fallback: choose newest, non-manifest, non-log file with non-trivial size.
    $skipExt = @(".txt",".log",".json",".yaml",".yml",".xml",".sha256",".md")
    $candidate = $all |
        Where-Object { ($skipExt -notcontains $_.Extension.ToLowerInvariant()) -and $_.Length -gt 102400 } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $candidate
}

