function Get-DetectionConfigPath([string]$ScriptPath) {
    if ([string]::IsNullOrWhiteSpace($ScriptPath)) { return "" }
    $dir = Split-Path -Path $ScriptPath -Parent
    if ([string]::IsNullOrWhiteSpace($dir)) { return "" }
    return (Join-Path $dir "WinGet-PSADT GUI Tool.Detection.json")
}

function Get-DetectionDefaults([string]$AppName,[string]$AppVersion) {
    $name = if ([string]::IsNullOrWhiteSpace($AppName)) { "Application" } else { $AppName }
    $ver = if ([string]::IsNullOrWhiteSpace($AppVersion)) { "" } else { [string]$AppVersion }
    return [ordered]@{
        DetectionNameRegex    = '^' + [regex]::Escape($name) + '(?:\s|$)'
        DetectionUseVersion   = if ([string]::IsNullOrWhiteSpace($ver)) { "false" } else { "true" }
        DetectionVersion      = $ver
        DetectionRegistryRoots= 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*;HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
}

function Get-DetectionConfigForScript([string]$ScriptPath,[string]$AppName,[string]$AppVersion) {
    $d = Get-DetectionDefaults -AppName $AppName -AppVersion $AppVersion
    $cfgPath = Get-DetectionConfigPath -ScriptPath $ScriptPath
    if ([string]::IsNullOrWhiteSpace($cfgPath) -or !(Test-Path $cfgPath)) { return $d }
    try {
        $obj = Get-Content -LiteralPath $cfgPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        foreach ($k in @("DetectionNameRegex","DetectionUseVersion","DetectionVersion","DetectionRegistryRoots")) {
            if ($obj.PSObject.Properties.Name -contains $k) {
                $v = [string]$obj.$k
                if ($null -ne $v) { $d[$k] = $v }
            }
        }
    } catch {}
    return $d
}

function Save-DetectionConfigForScript([string]$ScriptPath,[hashtable]$Config) {
    $cfgPath = Get-DetectionConfigPath -ScriptPath $ScriptPath
    if ([string]::IsNullOrWhiteSpace($cfgPath)) { throw "Invalid detection config path." }
    $obj = [ordered]@{
        DetectionNameRegex     = [string]$Config["DetectionNameRegex"]
        DetectionUseVersion    = [string]$Config["DetectionUseVersion"]
        DetectionVersion       = [string]$Config["DetectionVersion"]
        DetectionRegistryRoots = [string]$Config["DetectionRegistryRoots"]
    }
    $json = $obj | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($cfgPath,$json,[System.Text.Encoding]::UTF8)
}

