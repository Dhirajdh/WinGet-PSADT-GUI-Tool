function New-PSADTTemplateSafe([string]$Destination,[string]$Name,[bool]$Force = $true) {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    $hostPath = if ($pwsh -and (Test-Path $pwsh.Source)) { $pwsh.Source } else { Get-WindowsPowerShellPath }
    Write-DebugLog "INFO" ("TemplateCreateStart | Name={0} | Destination={1} | Force={2} | Host={3}" -f $Name,$Destination,$Force,$hostPath)

    # First try in current session (works for users with a healthy module load path).
    try {
        if ($Force) {
            New-ADTTemplate -Destination $Destination -Name $Name -Force -ErrorAction Stop | Out-Null
        } else {
            New-ADTTemplate -Destination $Destination -Name $Name -ErrorAction Stop | Out-Null
        }
        Write-DebugLog "INFO" ("TemplateCreateCurrentSessionSuccess | Name={0}" -f $Name)
        return [PSCustomObject]@{ ExitCode = 0; Output = "Created in current session." }
    } catch {
        Write-DebugLog "WARN" ("TemplateCreateCurrentSessionFailed | Name={0} | {1}" -f $Name,$_.Exception.Message)
    }

    $destEsc = $Destination.Replace("'","''")
    $nameEsc = $Name.Replace("'","''")
    $cmd = @"
`$ErrorActionPreference = 'Stop'
try {
    New-ADTTemplate -Destination '$destEsc' -Name '$nameEsc' $(if($Force){'-Force'}) -ErrorAction Stop | Out-Null
    exit 0
} catch {
    Write-Error `$_.Exception.Message
    exit 1
}
"@
    $result = Invoke-WindowsPowerShellCommand $cmd
    Write-DebugLog "INFO" ("TemplateCreateEnd | Name={0} | ExitCode={1} | Output={2}" -f $Name,$result.ExitCode,$result.Output)
    if ($result.ExitCode -eq 0) { return $result }

    # Final fallback: scaffold minimal package layout when module/template cmd cannot be loaded.
    try {
        $pkgRoot = Join-Path $Destination $Name
        if (!(Test-Path $pkgRoot)) { New-Item -ItemType Directory -Path $pkgRoot -Force | Out-Null }
        foreach ($d in @("Assets","Config","Files","Output","PSAppDeployToolkit","PSAppDeployToolkit.Extensions","Strings","SupportFiles")) {
            $p = Join-Path $pkgRoot $d
            if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
        }

        $mod = Get-Module -ListAvailable -Name PSAppDeployToolkit,PSAppDeployToolkit.Tools -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending | Select-Object -First 1
        if ($mod -and $mod.ModuleBase -and (Test-Path $mod.ModuleBase)) {
            Copy-Item -Path (Join-Path $mod.ModuleBase "*") -Destination (Join-Path $pkgRoot "PSAppDeployToolkit") -Recurse -Force -ErrorAction SilentlyContinue
            Write-DebugLog "INFO" ("TemplateFallbackCopiedModule | Source={0}" -f $mod.ModuleBase)
        } else {
            Write-DebugLog "WARN" "TemplateFallbackNoModuleFilesFound"
        }

        $scriptPath = Join-Path $pkgRoot "Invoke-AppDeployToolkit.ps1"
        if (!(Test-Path $scriptPath)) {
            $templateScript = @'
#requires -version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Repair')]
    [string]$DeploymentType = 'Install'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$dirFiles = Join-Path $scriptRoot 'Files'

function Invoke-Install {
    ## <Perform Installation tasks here>
}
function Invoke-Uninstall {
    ## <Perform Uninstallation tasks here>
}
function Invoke-Repair {
    ## <Perform Repair tasks here>
}

switch ($DeploymentType) {
    'Install'   { Invoke-Install }
    'Uninstall' { Invoke-Uninstall }
    'Repair'    { Invoke-Repair }
}
'@
            [System.IO.File]::WriteAllText($scriptPath,$templateScript,[System.Text.Encoding]::UTF8)
        }

        Write-DebugLog "WARN" ("TemplateFallbackUsed | PackageRoot={0}" -f $pkgRoot)
        return [PSCustomObject]@{ ExitCode = 0; Output = "Fallback template scaffolded (New-ADTTemplate unavailable)." }
    } catch {
        Write-DebugLog "ERROR" ("TemplateFallbackFailed | {0}" -f $_.Exception.Message)
        return $result
    }
}

function Normalize-PSADTTemplateSections([string]$ScriptPath) {
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { return }
    $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
    $fixes = @(
        @{
            Fn = "Install-ADTDeployment"
            Next = "Uninstall-ADTDeployment"
            Map = @{
                "## MARK: Uninstall" = "## MARK: Install"
                "## MARK: Post-Uninstallation" = "## MARK: Post-Install"
                "## <Perform Pre-Uninstallation tasks here>" = "## <Perform Pre-Installation tasks here>"
                "## <Perform Uninstallation tasks here>" = "## <Perform Installation tasks here>"
                "## <Perform Post-Uninstallation tasks here>" = "## <Perform Post-Installation tasks here>"
            }
        },
        @{
            Fn = "Uninstall-ADTDeployment"
            Next = "Repair-ADTDeployment"
            Map = @{
                "## MARK: Install" = "## MARK: Uninstall"
                "## MARK: Post-Install" = "## MARK: Post-Uninstallation"
                "## <Perform Pre-Installation tasks here>" = "## <Perform Pre-Uninstallation tasks here>"
                "## <Perform Installation tasks here>" = "## <Perform Uninstallation tasks here>"
                "## <Perform Post-Installation tasks here>" = "## <Perform Post-Uninstallation tasks here>"
            }
        },
        @{
            Fn = "Repair-ADTDeployment"
            Next = ""
            Map = @{
                "## MARK: Install" = "## MARK: Repair"
                "## MARK: Post-Install" = "## MARK: Post-Repair"
                "## <Perform Pre-Installation tasks here>" = "## <Perform Pre-Repair tasks here>"
                "## <Perform Installation tasks here>" = "## <Perform Repair tasks here>"
                "## <Perform Post-Installation tasks here>" = "## <Perform Post-Repair tasks here>"
                "## MARK: Uninstall" = "## MARK: Repair"
                "## MARK: Post-Uninstallation" = "## MARK: Post-Repair"
                "## <Perform Pre-Uninstallation tasks here>" = "## <Perform Pre-Repair tasks here>"
                "## <Perform Uninstallation tasks here>" = "## <Perform Repair tasks here>"
                "## <Perform Post-Uninstallation tasks here>" = "## <Perform Post-Repair tasks here>"
            }
        }
    )
    foreach ($f in $fixes) {
        $pattern = if ([string]::IsNullOrWhiteSpace($f.Next)) {
            "(?ms)function\s+$([regex]::Escape($f.Fn))\b.*$"
        } else {
            "(?ms)function\s+$([regex]::Escape($f.Fn))\b.*?(?=^\s*function\s+$([regex]::Escape($f.Next))\b)"
        }
        $m = [regex]::Match($text,$pattern)
        if (!$m.Success) { continue }
        $blk = $m.Value
        foreach ($k in $f.Map.Keys) {
            $blk = $blk -replace [regex]::Escape($k), [string]$f.Map[$k]
        }
        $text = $text.Substring(0,$m.Index) + $blk + $text.Substring($m.Index + $m.Length)
    }
    # Hard line-based removal of the default Post-Install completion prompt block
    # inside Install-ADTDeployment:
    #   ## Display a message at the end of the install.
    #   if (!$adtSession.UseDefaultMsi) { ... }
    $mInstallFn = [regex]::Match($text,"(?ms)function\s+Install-ADTDeployment\b.*?(?=^\s*function\s+Uninstall-ADTDeployment\b)")
    if ($mInstallFn.Success) {
        $installFn = $mInstallFn.Value
        $src = @($installFn -split "`r?`n")
        $dst = [System.Collections.Generic.List[string]]::new()
        $skipComment = $false
        $skipIfBlock = $false
        $braceDepth = 0
        foreach ($ln in $src) {
            $t = $ln.Trim()
            if (!$skipComment -and !$skipIfBlock -and $t -eq '## Display a message at the end of the install.') {
                $skipComment = $true
                continue
            }
            if ($skipComment -and !$skipIfBlock) {
                if ($t -match '^if\s*\(!\$adtSession\.UseDefaultMsi\)\s*$') {
                    $skipIfBlock = $true
                    $braceDepth = 0
                    continue
                }
                if ([string]::IsNullOrWhiteSpace($t)) { continue }
                $skipComment = $false
            }
            if ($skipIfBlock) {
                $openCount = ([regex]::Matches($ln,'\{')).Count
                $closeCount = ([regex]::Matches($ln,'\}')).Count
                $braceDepth += ($openCount - $closeCount)
                if ($braceDepth -le 0 -and $closeCount -gt 0) {
                    $skipIfBlock = $false
                    $skipComment = $false
                }
                continue
            }
            $dst.Add($ln) | Out-Null
        }
        $installFn = ($dst -join "`r`n")
        $text = $text.Substring(0,$mInstallFn.Index) + $installFn + $text.Substring($mInstallFn.Index + $mInstallFn.Length)
    }
    [System.IO.File]::WriteAllText($ScriptPath,$text,[System.Text.Encoding]::UTF8)
}

