function Flush-UI {
    try {
        $Window.UpdateLayout()
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Render,
            [System.Windows.Threading.DispatcherOperationCallback]{ param($f) $f.Continue = $false; return $null },
            $frame
        ) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    } catch {}
}

function Get-WingetPath {
    $p = Get-Command winget -ErrorAction SilentlyContinue
    if ($p) { return $p.Source }
    $loc = "$env:LocalAppData\Microsoft\WindowsApps\winget.exe"
    if (Test-Path $loc) { return $loc }
    return $null
}

function Get-SafeName([string]$Name) {
    return ($Name -replace '[\\/:*?"<>|]','_').Trim()
}

function Get-SectionMarker([string]$Section) {
    $name = if ($null -eq $Section) { "" } else { $Section }
    switch ($name.Trim()) {
        "Pre-Install"   { return "## <Perform Pre-Installation tasks here>" }
        "Install"       { return "## <Perform Installation tasks here>" }
        "Post-Install"  { return "## <Perform Post-Installation tasks here>" }
        "Pre-Uninstall" { return "## <Perform Pre-Uninstallation tasks here>" }
        "Uninstall"     { return "## <Perform Uninstallation tasks here>" }
        "Post-Uninstall"{ return "## <Perform Post-Uninstallation tasks here>" }
        "Pre-Repair"    { return "## <Perform Pre-Repair tasks here>" }
        "Repair"        { return "## <Perform Repair tasks here>" }
        "Post-Repair"   { return "## <Perform Post-Repair tasks here>" }
        default         { return "## <Perform Pre-Installation tasks here>" }
    }
}

function Get-IntuneWinOutputName([string]$AppName,[string]$Version) {
    $n = if ([string]::IsNullOrWhiteSpace($AppName)) { "Package" } else { Get-SafeName $AppName }
    $v = if ([string]::IsNullOrWhiteSpace($Version) -or $Version -eq "N/A") { "UnknownVersion" } else { Get-SafeName $Version }
    $n = ($n -replace '\s+','_')
    $v = ($v -replace '\s+','_')
    return "{0}_{1}.intunewin" -f $n,$v
}

function Get-WindowsPowerShellPath {
    $ps51 = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $ps51) { return $ps51 }
    return "powershell.exe"
}

function Invoke-WindowsPowerShellCommand([string]$CommandText) {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    $ps51 = if ($pwsh -and (Test-Path $pwsh.Source)) { $pwsh.Source } else { Get-WindowsPowerShellPath }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($CommandText))
    $tmpOut = Join-Path $env:TEMP "psadt_subproc_$([Guid]::NewGuid().ToString('N')).out.log"
    $tmpErr = Join-Path $env:TEMP "psadt_subproc_$([Guid]::NewGuid().ToString('N')).err.log"
    $args = @("-NoProfile","-ExecutionPolicy","Bypass","-EncodedCommand",$encoded)
    $p = Start-Process -FilePath $ps51 -ArgumentList $args -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr
    $output = ""
    try {
        $outTxt = if (Test-Path $tmpOut) { Get-Content -LiteralPath $tmpOut -Raw -ErrorAction SilentlyContinue } else { "" }
        $errTxt = if (Test-Path $tmpErr) { Get-Content -LiteralPath $tmpErr -Raw -ErrorAction SilentlyContinue } else { "" }
        $output = (($outTxt, $errTxt) -join "`n").Trim()
    } catch {}
    try { if (Test-Path $tmpOut) { Remove-Item -LiteralPath $tmpOut -Force -ErrorAction SilentlyContinue } } catch {}
    try { if (Test-Path $tmpErr) { Remove-Item -LiteralPath $tmpErr -Force -ErrorAction SilentlyContinue } } catch {}
    return [PSCustomObject]@{
        ExitCode = $p.ExitCode
        StdOut   = $outTxt
        StdErr   = $errTxt
        Output   = $output
    }
}

function Get-PackageContext([object]$SelectedItem) {
    $packageRoot = $null
    $appName = $null
    if ($SelectedItem -and $SelectedItem.Name) {
        $appName = [string]$SelectedItem.Name
        $safe = Get-SafeName $appName
        $packageRoot = Join-Path $Global:PackageRoot $safe
    } elseif ($Global:SelectedPackage -and (Test-Path $Global:SelectedPackage)) {
        $packageRoot = $Global:SelectedPackage
        $appName = Split-Path $packageRoot -Leaf
    }
    if ([string]::IsNullOrWhiteSpace($packageRoot)) { return $null }

    $filesFolder = Join-Path $packageRoot "Files"
    $scriptPath  = Join-Path $packageRoot "Invoke-AppDeployToolkit.ps1"
    $installer   = Find-DownloadedInstaller $filesFolder
    return [PSCustomObject]@{
        PackageRoot  = $packageRoot
        FilesFolder  = $filesFolder
        ScriptPath   = $scriptPath
        AppName      = if ($appName) { $appName } else { Split-Path $packageRoot -Leaf }
        HasPackage   = (Test-Path $packageRoot)
        HasFiles     = (Test-Path $filesFolder)
        HasScript    = (Test-Path $scriptPath)
        Installer    = $installer
        HasInstaller = ($null -ne $installer)
    }
}

