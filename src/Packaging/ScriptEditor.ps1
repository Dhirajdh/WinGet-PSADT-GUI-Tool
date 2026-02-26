function Get-AppDetailsDefaults([string]$AppName,[string]$Version) {
    $spec = Get-AppDetailFieldSpec
    $d = [ordered]@{}
    foreach ($f in $spec) {
        $d[$f.Key] = [string]$f.Default
    }
    $d["AppName"] = if ([string]::IsNullOrWhiteSpace($AppName)) { "Application" } else { $AppName }
    $d["AppVersion"] = if ([string]::IsNullOrWhiteSpace($Version)) { "1.0.0" } else { $Version }
    return $d
}

function Get-AppDetailFieldSpec {
    return @(
        @{Key="AppVendor";Label="App Vendor";Kind="string";Default="Unknown Publisher"},
        @{Key="AppName";Label="App Name";Kind="string";Default="Application"},
        @{Key="AppVersion";Label="App Version";Kind="string";Default="1.0.0"},
        @{Key="AppArch";Label="App Arch";Kind="string";Default="x64"},
        @{Key="AppLang";Label="App Language";Kind="string";Default="EN"},
        @{Key="AppRevision";Label="App Revision";Kind="string";Default="01"},
        @{Key="AppSuccessExitCodes";Label="App Success Exit Codes";Kind="raw";Default="@(0)"},
        @{Key="AppRebootExitCodes";Label="App Reboot Exit Codes";Kind="raw";Default="@(1641, 3010)"},
        @{Key="AppProcessesToClose";Label="App Processes To Close";Kind="raw";Default="@()";Example=(Get-CloseProcessesExample)},
        @{Key="AppIconPath";Label="App Icon Path";Kind="string";Default=""},
        @{Key="AppScriptVersion";Label="Script Version";Kind="string";Default="1.0.0"},
        @{Key="AppScriptDate";Label="Script Date";Kind="string";Default=(Get-Date -Format "yyyy-MM-dd")},
        @{Key="AppScriptAuthor";Label="Script Author";Kind="string";Default=$env:USERNAME},
        @{Key="RequireAdmin";Label="Require Admin";Kind="raw";Default='$true'},
        @{Key="InstallName";Label="Install Name";Kind="string";Default=""},
        @{Key="InstallTitle";Label="Install Title";Kind="string";Default=""}
    )
}

function Get-VendorFromPackageId([string]$PackageId) {
    if ([string]::IsNullOrWhiteSpace($PackageId)) { return "" }
    $parts = $PackageId.Split(".")
    if ($parts.Count -gt 0) { return $parts[0] }
    return ""
}

function Find-PackageIcon([string]$PackageRoot,[string]$FilesFolder) {
    $ext = @(".ico",".png",".jpg",".jpeg",".bmp")
    $candidates = @()
    foreach ($root in @($FilesFolder, (Join-Path $PackageRoot "SupportFiles"), (Join-Path $PackageRoot "Assets"), $PackageRoot)) {
        if ([string]::IsNullOrWhiteSpace($root) -or !(Test-Path $root)) { continue }
        $hits = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $ext -contains $_.Extension.ToLowerInvariant() } |
            Sort-Object LastWriteTime -Descending
        if ($hits) { $candidates += $hits }
    }
    if ($candidates.Count -gt 0) { return $candidates[0].FullName }
    return ""
}

function Ensure-AppDetailsDefaultsInScript([string]$ScriptPath,[string]$AppName,[string]$Version,[string]$Vendor,[string]$PackageRoot,[string]$FilesFolder) {
    $cur = Get-AppDetailsFromScript -ScriptPath $ScriptPath -AppName $AppName -Version $Version
    $changed = $false
    if ([string]::IsNullOrWhiteSpace($cur.AppName)) { $cur.AppName = $AppName; $changed = $true }
    if ([string]::IsNullOrWhiteSpace($cur.AppVersion) -or $cur.AppVersion -eq "1.0.0") { $cur.AppVersion = $Version; $changed = $true }
    if ([string]::IsNullOrWhiteSpace($cur.AppVendor) -or $cur.AppVendor -eq "Unknown Publisher") {
        if (![string]::IsNullOrWhiteSpace($Vendor)) { $cur.AppVendor = $Vendor; $changed = $true }
    }
    if ([string]::IsNullOrWhiteSpace($cur.AppIconPath)) {
        $icon = Find-PackageIcon -PackageRoot $PackageRoot -FilesFolder $FilesFolder
        if (![string]::IsNullOrWhiteSpace($icon)) { $cur.AppIconPath = $icon; $changed = $true }
    }
    if ($changed) {
        Save-AppDetailsToScript -ScriptPath $ScriptPath -Details $cur
    }
}

function Get-AppDetailsFromScript([string]$ScriptPath,[string]$AppName,[string]$Version) {
    $defaults = Get-AppDetailsDefaults -AppName $AppName -Version $Version
    $spec = Get-AppDetailFieldSpec
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { return $defaults }
    try {
        $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
        $mSession = [regex]::Match($text,'(?ms)^\s*\$adtSession\s*=\s*@\{(?<body>.*?)(?m)^\s*\}')
        if ($mSession.Success) {
            $body = $mSession.Groups['body'].Value
            foreach ($f in $spec) {
                $k = $f.Key
                $m = [regex]::Match($body, "(?m)^\s*" + [regex]::Escape($k) + "\s*=\s*(.+?)(?:\s*#.*)?$")
                if ($m.Success) {
                    $raw = $m.Groups[1].Value.Trim()
                    if ($f.Kind -eq "string") {
                        if ($raw -match "^'(.*)'$") {
                            $defaults[$k] = ($Matches[1] -replace "''","'")
                        } else {
                            $defaults[$k] = $raw
                        }
                    } else {
                        $defaults[$k] = $raw
                    }
                }
            }
        }
    } catch {}
    return $defaults
}

function Save-AppDetailsToScript([string]$ScriptPath,[hashtable]$Details) {
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { throw "Script file not found: $ScriptPath" }
    $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
    # Remove legacy generator block if present.
    $text = [regex]::Replace($text,'(?s)\r?\n?\s*# WinGet-PSADT GUI Tool:BEGIN-APPDETAILS.*?# WinGet-PSADT GUI Tool:END-APPDETAILS\s*\r?\n?','')

    $mSession = [regex]::Match($text,'(?ms)^\s*\$adtSession\s*=\s*@\{(?<body>.*?)(?m)^\s*\}')
    if (!$mSession.Success) {
        throw "Could not find `$adtSession hashtable in Invoke-AppDeployToolkit.ps1"
    }
    $body = $mSession.Groups['body'].Value
    $spec = Get-AppDetailFieldSpec
    foreach ($f in $spec) {
        $k = $f.Key
        $v = if ($Details.ContainsKey($k)) { [string]$Details[$k] } else { [string]$f.Default }
        if ([string]::IsNullOrWhiteSpace($v)) { $v = [string]$f.Default }
        $expr = if ($f.Kind -eq "string") { "'" + ($v -replace "'","''") + "'" } else { $v.Trim() }
        $p = "(?m)^(\s*" + [regex]::Escape($k) + "\s*=\s*)(.+?)(\s*(?:#.*)?$)"
        if ([regex]::IsMatch($body,$p)) {
            $body = [regex]::Replace($body,$p,('$1' + $expr + '$3'),1)
        } else {
            $insert = "    $k = $expr"
            if ($body -match "(?m)^\s*DeployAppScriptFriendlyName\s*=") {
                $body = [regex]::Replace($body,"(?m)^(\s*DeployAppScriptFriendlyName\s*=.*)$","$insert`r`n`$1",1)
            } else {
                $body = $body + "`r`n" + $insert
            }
        }
    }

    $newSession = '$adtSession = @{' + $body + "`r`n}"
    $text = $text.Substring(0,$mSession.Index) + $newSession + $text.Substring($mSession.Index + $mSession.Length)
    [System.IO.File]::WriteAllText($ScriptPath,$text,[System.Text.Encoding]::UTF8)
}

function Get-SAIWDefaults {
    $d = [ordered]@{}
    foreach ($f in (Get-SAIWFieldSpec)) {
        $d[$f.Key] = [string]$f.Default
    }
    return $d
}

function Get-SAIWFieldSpec {
    $spec = [System.Collections.Generic.List[hashtable]]::new()
    $meta = $null
    if ($Global:PSADTFunctions -and $Global:PSADTFunctions.Contains("User Interface")) {
        $ui = $Global:PSADTFunctions["User Interface"]
        if ($ui -and $ui.Contains("Show-ADTInstallationWelcome")) {
            $meta = $ui["Show-ADTInstallationWelcome"]
        }
    }
    if ($meta -and $meta.Params) {
        foreach ($pName in $meta.Params.Keys) {
            $key = ([string]$pName).Trim()
            if ($key.StartsWith("-")) { $key = $key.Substring(1) }
            $pDef = $meta.Params[$pName]
            $defVal = ""
            if (($pDef -is [System.Collections.IDictionary]) -and $pDef.Contains("Default")) {
                $defVal = [string]$pDef.Default
            } elseif (($pDef.Type -eq "switch") -or ($pDef.ParamType -eq "SwitchParameter")) {
                $defVal = '$false'
            }
            $label = $key
            $isBool = (($pDef.Type -eq "switch") -or ($pDef.ParamType -eq "SwitchParameter") -or ($defVal -in @('$true','$false','true','false')))
            $isEnum = (($pDef.Type -eq "combo") -or (($pDef -is [System.Collections.IDictionary]) -and $pDef.Contains("Options") -and @($pDef.Options).Count -gt 0))
            $opts = @()
            if ($isEnum -and ($pDef -is [System.Collections.IDictionary]) -and $pDef.Contains("Options")) { $opts = @($pDef.Options) }
            $spec.Add(@{
                Key     = $key
                Label   = $label
                Default = $defVal
                IsBool  = $isBool
                IsEnum  = $isEnum
                Options = $opts
            }) | Out-Null
        }
    }
    if ($spec.Count -eq 0) {
        # Safe fallback when metadata cannot be discovered.
        $spec.Add(@{Key="AllowDefer";Label="AllowDefer";Default='$true';IsBool=$true;IsEnum=$false;Options=@()}) | Out-Null
        $spec.Add(@{Key="DeferTimes";Label="DeferTimes";Default='3';IsBool=$false;IsEnum=$false;Options=@()}) | Out-Null
        $spec.Add(@{Key="CheckDiskSpace";Label="CheckDiskSpace";Default='$true';IsBool=$true;IsEnum=$false;Options=@()}) | Out-Null
        $spec.Add(@{Key="PersistPrompt";Label="PersistPrompt";Default='$true';IsBool=$true;IsEnum=$false;Options=@()}) | Out-Null
    }
    return @($spec)
}

function Get-SAIWParamsFromScript([string]$ScriptPath) {
    $d = @{}
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { return $d }
    try {
        $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
        $m = [regex]::Match($text,'(?ms)^\s*\$saiwParams\s*=\s*@\{(?<body>.*?)(?m)^\s*\}')
        if ($m.Success) {
            $body = $m.Groups['body'].Value
            foreach ($k in (Get-SAIWFieldSpec | ForEach-Object { $_.Key })) {
                $mx = [regex]::Match($body,"(?m)^\s*" + [regex]::Escape($k) + "\s*=\s*(.+?)(?:\s*#.*)?$")
                if ($mx.Success) { $d[$k] = $mx.Groups[1].Value.Trim() }
            }
        }
    } catch {}
    return $d
}

function Save-SAIWParamsToScript([string]$ScriptPath,[hashtable]$Params) {
    function Format-SAIWValue([hashtable]$Field,[string]$RawValue) {
        $v = if ($null -eq $RawValue) { "" } else { [string]$RawValue }
        if ([string]::IsNullOrWhiteSpace($v)) { return "" }
        $t = $v.Trim()
        if ($Field.IsBool) { return $t }
        if ($t -match '^-?\d+(\.\d+)?$') { return $t }
        if ($t -match "^\$|^\(|^\{|^\[|^@\(") { return $t }
        if ($t -match "^'.*'$|^"".*""$") { return $t }
        $esc = $t.Replace("'","''")
        return "'" + $esc + "'"
    }
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { throw "Script file not found: $ScriptPath" }
    $spec = Get-SAIWFieldSpec
    $defaults = Get-SAIWDefaults
    $p = @{}
    foreach ($k in ($spec | ForEach-Object { $_.Key })) {
        if ($Params.ContainsKey($k)) { $p[$k] = ([string]$Params[$k]).Trim() }
    }
    $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
    $mInstall = [regex]::Match($text,'(?ms)function\s+Install-ADTDeployment\b.*?(?=^\s*function\s+Uninstall-ADTDeployment\b)')
    if (!$mInstall.Success) { throw "Could not find Install-ADTDeployment function block." }
    $installBlock = $mInstall.Value

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('    $saiwParams = @{') | Out-Null
    $falseTokens = @('$false','false')
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($f in $spec) {
        $k = $f.Key
        $v = if ($p.Contains($k)) { [string]$p[$k] } else { "" }
        if ([string]::IsNullOrWhiteSpace($v)) { continue }
        $vt = $v.Trim()
        if ($f.IsBool -and ($falseTokens -contains $vt.ToLowerInvariant())) { continue }
        if ((-not $f.IsBool) -and $defaults.Contains($k) -and ([string]$defaults[$k]).Trim() -eq $vt) { continue }
        $fmt = Format-SAIWValue -Field $f -RawValue $vt
        if (![string]::IsNullOrWhiteSpace($fmt)) {
            $entries.Add([PSCustomObject]@{ Key = $k; Value = $fmt }) | Out-Null
        }
    }
    $maxKeyLen = 0
    foreach ($e in $entries) {
        if ($e.Key.Length -gt $maxKeyLen) { $maxKeyLen = $e.Key.Length }
    }
    foreach ($e in $entries) {
        $padKey = $e.Key.PadRight($maxKeyLen)
        $lines.Add(("        {0} = {1}" -f $padKey, $e.Value)) | Out-Null
    }
    $lines.Add('    }') | Out-Null
    $lines.Add('    if ($adtSession.AppProcessesToClose.Count -gt 0)') | Out-Null
    $lines.Add('    {') | Out-Null
    $lines.Add('        $saiwParams.Add(''CloseProcesses'', $adtSession.AppProcessesToClose)') | Out-Null
    $lines.Add('    }') | Out-Null
    $lines.Add('    ## Show Welcome Message, close processes if specified, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt.') | Out-Null
    $lines.Add('    Show-ADTInstallationWelcome @saiwParams') | Out-Null
    $block = ($lines -join "`r`n")

    # Work only inside Pre-Install phase section.
    $mPre = [regex]::Match($installBlock,'(?ms)^\s*##\s*MARK:\s*Pre-Install\b.*?(?=^\s*##\s*MARK:\s*Install\b)')
    if (!$mPre.Success) { throw "Could not find Pre-Install phase section in Install-ADTDeployment." }
    $preSection = $mPre.Value

    # Remove existing SAIW block + welcome line in Pre-Install only.
    $preSection = [regex]::Replace($preSection,'(?ms)^\s*\$saiwParams\s*=\s*@\{.*?^\s*\}\s*','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*if\s*\(\$adtSession\.AppProcessesToClose\.Count\s*-gt\s*0(?:\s*-and\s*-not\s+\$saiwParams\.ContainsKey\(''CloseProcesses''\))?\)\s*$','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*\$saiwParams\.Add\(''CloseProcesses''\s*,\s*\$adtSession\.AppProcessesToClose\)\s*$','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*Show-ADTInstallationWelcome\s+@saiwParams\s*$','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*##\s*Show Welcome Message.*$','')
    $preSection = [regex]::Replace($preSection,'(?ms)^\s*\{\s*\r?\n\s*\}\s*(?:\r?\n)?','')

    # Insert before progress comment, else before Pre-Install tasks marker.
    $insertAt = -1
    $mProg = [regex]::Match($preSection,'(?m)^\s*##\s*Show Progress Message.*$')
    if ($mProg.Success) { $insertAt = $mProg.Index }
    else {
        $mMarker = [regex]::Match($preSection,'(?m)^\s*##\s*<Perform Pre-Installation tasks here>\s*$')
        if ($mMarker.Success) { $insertAt = $mMarker.Index }
    }
    if ($insertAt -lt 0) { $insertAt = $preSection.Length }
    $preSection = $preSection.Substring(0,$insertAt).TrimEnd() + "`r`n`r`n" + $block + "`r`n`r`n" + $preSection.Substring($insertAt).TrimStart()

    $installBlock = $installBlock.Substring(0,$mPre.Index) + $preSection + $installBlock.Substring($mPre.Index + $mPre.Length)

    $text = $text.Substring(0,$mInstall.Index) + $installBlock + $text.Substring($mInstall.Index + $mInstall.Length)
    [System.IO.File]::WriteAllText($ScriptPath,$text,[System.Text.Encoding]::UTF8)
}

