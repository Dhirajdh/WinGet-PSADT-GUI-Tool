function Start-IntuneUploadAssistant(
    [string]$PackageRoot,
    [string]$IntuneWinPath,
    [string]$DefaultDisplayName,
    [string]$DefaultPublisher,
    [string]$DefaultDescription,
    [string]$IconPath,
    [string]$DefaultAppVersion = "",
    [string]$DefaultInformationUrl = "",
    [string]$DefaultPrivacyUrl = "",
    [string]$DefaultDeveloper = "",
    [string]$DefaultOwner = "",
    [string]$DefaultNotes = "",
    [string]$DetectionNameRegex = "",
    [string]$DetectionUseVersion = "",
    [string]$DetectionVersion = "",
    [string]$DetectionRegistryRoots = ""
) {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    $psPath = if ($pwsh -and (Test-Path $pwsh.Source)) { $pwsh.Source } else { Get-WindowsPowerShellPath }
    $tmpScript = Join-Path $env:TEMP ("psadt_intune_upload_{0}.ps1" -f [Guid]::NewGuid().ToString("N"))
    $paramNames = @(
        'PackageRoot','IntuneWinPath','DefaultDisplayName','DefaultPublisher','DefaultDescription','IconPath',
        'DefaultAppVersion','DefaultInformationUrl','DefaultPrivacyUrl','DefaultDeveloper','DefaultOwner','DefaultNotes',
        'DetectionNameRegex','DetectionUseVersion','DetectionVersion','DetectionRegistryRoots'
    )
    foreach ($n in $paramNames) {
        if ($null -eq (Get-Variable -Name $n -ValueOnly)) { Set-Variable -Name $n -Value "" }
    }
    $pkgEsc = $PackageRoot.Replace("'","''")
    $fileEsc = $IntuneWinPath.Replace("'","''")
    $nameEsc = $DefaultDisplayName.Replace("'","''")
    $pubEsc = $DefaultPublisher.Replace("'","''")
    $descEsc = $DefaultDescription.Replace("'","''")
    $iconEsc = $IconPath.Replace("'","''")
    $appVerEsc = $DefaultAppVersion.Replace("'","''")
    $infoUrlEsc = $DefaultInformationUrl.Replace("'","''")
    $privacyUrlEsc = $DefaultPrivacyUrl.Replace("'","''")
    $developerEsc = $DefaultDeveloper.Replace("'","''")
    $ownerEsc = $DefaultOwner.Replace("'","''")
    $notesEsc = $DefaultNotes.Replace("'","''")
    $detRegexEsc = $DetectionNameRegex.Replace("'","''")
    $detUseVerEsc = $DetectionUseVersion.Replace("'","''")
    $detVerEsc = $DetectionVersion.Replace("'","''")
    $detRootsEsc = $DetectionRegistryRoots.Replace("'","''")
    $runLog = Join-Path $Global:LogFolder ("intune-upload-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $runLogEsc = $runLog.Replace("'","''")
    $scriptText = @"
param()
`$ErrorActionPreference = 'Stop'
`$packageRoot = '$pkgEsc'
`$intuneWinPath = '$fileEsc'
`$defaultName = '$nameEsc'
`$defaultPublisher = '$pubEsc'
`$defaultDescription = '$descEsc'
`$iconPath = '$iconEsc'
`$defaultAppVersion = '$appVerEsc'
`$defaultInformationUrl = '$infoUrlEsc'
`$defaultPrivacyUrl = '$privacyUrlEsc'
`$defaultDeveloper = '$developerEsc'
`$defaultOwner = '$ownerEsc'
`$defaultNotes = '$notesEsc'
`$detectionNameRegex = '$detRegexEsc'
`$detectionUseVersion = '$detUseVerEsc'
`$detectionVersion = '$detVerEsc'
`$detectionRegistryRoots = '$detRootsEsc'
`$runLog = '$runLogEsc'

Start-Transcript -Path `$runLog -Force | Out-Null
Write-Host "PSADT Intune Upload Assistant" -ForegroundColor Cyan
Write-Host "Package: `$intuneWinPath" -ForegroundColor DarkGray

if (!(Test-Path `$intuneWinPath)) {
    throw "IntuneWin file not found: `$intuneWinPath"
}

if (-not (Get-Module -ListAvailable -Name IntuneWin32App -ErrorAction SilentlyContinue)) {
    Write-Host "IntuneWin32App module not found." -ForegroundColor Yellow
    Install-Module IntuneWin32App -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
}

Import-Module IntuneWin32App -Force -ErrorAction Stop
if (!(Get-Command Add-IntuneWin32App -ErrorAction SilentlyContinue)) {
    throw "Add-IntuneWin32App command not found in IntuneWin32App module."
}
if (!(Get-Command Connect-MSIntuneGraph -ErrorAction SilentlyContinue)) {
    throw "Connect-MSIntuneGraph command not found in IntuneWin32App module."
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue)) {
    Write-Host "Microsoft.Graph.Authentication module not found." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
}
Import-Module Microsoft.Graph.Authentication -Force -ErrorAction Stop

Write-Host "`nSigning in to Microsoft Graph..." -ForegroundColor Cyan
`$tenantForIntune = `$null
`$graphClientId = `$null
if (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue) {
    Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","DeviceManagementConfiguration.ReadWrite.All","DeviceManagementManagedDevices.Read.All","Group.Read.All","offline_access" -NoWelcome | Out-Null
    if (Get-Command Select-MgProfile -ErrorAction SilentlyContinue) { Select-MgProfile -Name beta }
    `$mgCtx = Get-MgContext
    if (`$mgCtx) {
        `$tenantForIntune = `$mgCtx.TenantId
        `$graphClientId = `$mgCtx.ClientId
        if (`$mgCtx.Account) { Write-Host ("Signed in as: {0}" -f `$mgCtx.Account) -ForegroundColor DarkGray }
    }
}

Write-Host "Connecting Intune module context..." -ForegroundColor Cyan
`$msiConn = Get-Command Connect-MSIntuneGraph -ErrorAction Stop
`$connectArgs = @{}
if (`$tenantForIntune -and `$msiConn.Parameters.ContainsKey('TenantID')) { `$connectArgs['TenantID'] = `$tenantForIntune }
if (`$msiConn.Parameters.ContainsKey('ClientID') -and `$graphClientId) { `$connectArgs['ClientID'] = `$graphClientId }
if (`$msiConn.Parameters.ContainsKey('Interactive')) { `$connectArgs['Interactive'] = `$true }
if (`$msiConn.Parameters.ContainsKey('ClientID') -and -not `$connectArgs.ContainsKey('ClientID')) {
    throw "Connect-MSIntuneGraph requires ClientID in this environment, but no ClientID was available from Graph sign-in context."
}
Connect-MSIntuneGraph @connectArgs | Out-Null

`$displayName = if ([string]::IsNullOrWhiteSpace(`$defaultName)) { "PSADT Package" } else { `$defaultName }
`$publisher = if ([string]::IsNullOrWhiteSpace(`$defaultPublisher)) { "Unknown Publisher" } else { `$defaultPublisher }
`$description = if ([string]::IsNullOrWhiteSpace(`$defaultDescription)) { "`$displayName via PSADT" } else { `$defaultDescription }
`$appVersion = if ([string]::IsNullOrWhiteSpace(`$defaultAppVersion)) { "" } else { `$defaultAppVersion }
`$informationUrl = if ([string]::IsNullOrWhiteSpace(`$defaultInformationUrl)) { "" } else { `$defaultInformationUrl }
`$privacyUrl = if ([string]::IsNullOrWhiteSpace(`$defaultPrivacyUrl)) { "" } else { `$defaultPrivacyUrl }
`$developer = if ([string]::IsNullOrWhiteSpace(`$defaultDeveloper)) { `$publisher } else { `$defaultDeveloper }
`$owner = if ([string]::IsNullOrWhiteSpace(`$defaultOwner)) { `$publisher } else { `$defaultOwner }
`$notes = if ([string]::IsNullOrWhiteSpace(`$defaultNotes)) { "" } else { `$defaultNotes }

`$installCmd = "powershell.exe -ExecutionPolicy Bypass -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent"
`$uninstallCmd = "powershell.exe -ExecutionPolicy Bypass -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall -DeployMode Silent"

`$addCmd = Get-Command Add-IntuneWin32App -ErrorAction Stop
function Get-AddParamName([System.Management.Automation.CommandInfo]`$Cmd,[string[]]`$Candidates) {
    foreach (`$n in `$Candidates) {
        foreach (`$k in `$Cmd.Parameters.Keys) {
            if (`$k -ieq `$n) { return `$k }
        }
    }
    return `$null
}
`$args = @{
    FilePath             = `$intuneWinPath
    DisplayName          = `$displayName
    Publisher            = `$publisher
    Description          = `$description
    InstallCommandLine   = `$installCmd
    UninstallCommandLine = `$uninstallCmd
}
`$optionalMetaParamNames = @()
if (`$addCmd.Parameters.ContainsKey('InstallExperience')) { `$args['InstallExperience'] = 'system' }
if (`$addCmd.Parameters.ContainsKey('RestartBehavior')) { `$args['RestartBehavior'] = 'suppress' }
foreach (`$m in @(
    @{ Value = [System.IO.Path]::GetFileName(`$intuneWinPath); Names = @('FileName','Filename','PackageFileName','ContentFileName') },
    @{ Value = `$appVersion;     Names = @('AppVersion','DisplayVersion') },
    @{ Value = `$informationUrl; Names = @('InformationUrl','InformationURL') },
    @{ Value = `$privacyUrl;     Names = @('PrivacyUrl','PrivacyURL') },
    @{ Value = `$developer;      Names = @('Developer') },
    @{ Value = `$owner;          Names = @('Owner') },
    @{ Value = `$notes;          Names = @('Notes') }
)) {
    if ([string]::IsNullOrWhiteSpace([string]`$m.Value)) { continue }
    `$pn = Get-AddParamName -Cmd `$addCmd -Candidates `$m.Names
    if (`$pn) {
        `$args[`$pn] = [string]`$m.Value
        if (`$optionalMetaParamNames -notcontains `$pn) { `$optionalMetaParamNames += `$pn }
    }
}
if (![string]::IsNullOrWhiteSpace(`$iconPath) -and (Test-Path `$iconPath) -and `$addCmd.Parameters.ContainsKey('Icon') -and (Get-Command New-IntuneWin32AppIcon -ErrorAction SilentlyContinue)) {
    try {
        `$icoObj = New-IntuneWin32AppIcon -FilePath `$iconPath
        if (`$icoObj) { `$args['Icon'] = `$icoObj }
    } catch {
        Write-Host "Icon load failed; continuing without icon." -ForegroundColor Yellow
    }
}

if (`$addCmd.Parameters.ContainsKey('DetectionRule') -and (Get-Command New-IntuneWin32AppDetectionRuleScript -ErrorAction SilentlyContinue)) {
    `$detectPath = Join-Path `$env:TEMP ("psadt_detect_{0}.ps1" -f [Guid]::NewGuid().ToString("N"))
    `$nameRegex = if ([string]::IsNullOrWhiteSpace(`$detectionNameRegex)) { ('^' + [regex]::Escape(`$displayName) + '(?:\s|$)') } else { `$detectionNameRegex }
    `$useVersion = if ([string]::IsNullOrWhiteSpace(`$detectionUseVersion)) { ![string]::IsNullOrWhiteSpace(`$appVersion) } else { [System.Convert]::ToBoolean(`$detectionUseVersion) }
    `$ver = if ([string]::IsNullOrWhiteSpace(`$detectionVersion)) { [string]`$appVersion } else { [string]`$detectionVersion }
    `$roots = @()
    if (![string]::IsNullOrWhiteSpace(`$detectionRegistryRoots)) {
        `$roots = @(`$detectionRegistryRoots -split ';' | ForEach-Object { `$_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace(`$_) })
    }
    if (`$roots.Count -eq 0) {
        `$roots = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
    }
    `$nameRegexEsc = `$nameRegex.Replace("'", "''")
    `$verEsc = `$ver.Replace("'", "''")
    `$rootsLit = (`$roots | ForEach-Object { "'" + (`$_.Replace("'", "''")) + "'" }) -join ','
    `$useVersionLit = if (`$useVersion) { '`$true' } else { '`$false' }
    `$detectTemplate = @'
`$roots = @(__ROOTS__)
`$apps = foreach (`$r in `$roots) { Get-ItemProperty -Path `$r -ErrorAction SilentlyContinue }
`$hits = `$apps | Where-Object { `$_.DisplayName -and (`$_.DisplayName -match '__NAME_REGEX__') }
if (__USE_VERSION__ -and ![string]::IsNullOrWhiteSpace('__VERSION__')) { `$hits = `$hits | Where-Object { [string]`$_.DisplayVersion -eq '__VERSION__' } }
if (`$hits -and (`$hits | Select-Object -First 1)) { Write-Output 'Installed'; exit 0 } else { exit 1 }
'@
    `$detectScript = `$detectTemplate.
        Replace('__ROOTS__', `$rootsLit).
        Replace('__NAME_REGEX__', `$nameRegexEsc).
        Replace('__USE_VERSION__', `$useVersionLit).
        Replace('__VERSION__', `$verEsc)
    Set-Content -LiteralPath `$detectPath -Value `$detectScript -Encoding UTF8
    try {
        `$det = New-IntuneWin32AppDetectionRuleScript -ScriptFile `$detectPath -RunAs32Bit `$false -EnforceSignatureCheck `$false
        `$args['DetectionRule'] = `$det
    } catch {
        Write-Host "Detection rule generation failed, upload may require manual rule setup." -ForegroundColor Yellow
    }
}

if (`$addCmd.Parameters.ContainsKey('RequirementRule') -and (Get-Command New-IntuneWin32AppRequirementRule -ErrorAction SilentlyContinue)) {
    try {
        `$reqCmd = Get-Command New-IntuneWin32AppRequirementRule -ErrorAction Stop
        `$archVal = "AllWithARM64"
        if (`$reqCmd.Parameters.ContainsKey('Architecture')) {
            `$validArch = @()
            try { `$validArch = @(`$reqCmd.Parameters['Architecture'].Attributes | Where-Object { `$_ -is [System.Management.Automation.ValidateSetAttribute] } | ForEach-Object { `$_.ValidValues } | Select-Object -First 1) } catch {}
            if (`$validArch -and (`$validArch -contains 'AllWithARM64')) { `$archVal = 'AllWithARM64' }
            elseif (`$validArch -and (`$validArch -contains 'All')) { `$archVal = 'All' }
            elseif (`$validArch -and (`$validArch -contains 'x64x86')) { `$archVal = 'x64x86' }
            elseif (`$validArch -and (`$validArch -contains 'x64')) { `$archVal = 'x64' }
        }
        `$req = New-IntuneWin32AppRequirementRule -Architecture `$archVal -MinimumSupportedWindowsRelease "W10_1607"
        `$args['RequirementRule'] = `$req
    } catch {}
}

Write-Host "`nStarting upload to Intune..." -ForegroundColor Cyan
Write-Host ("Display name : {0}" -f `$displayName) -ForegroundColor DarkGray
Write-Host ("Publisher    : {0}" -f `$publisher) -ForegroundColor DarkGray
Write-Host ("Package file : {0}" -f `$intuneWinPath) -ForegroundColor DarkGray
`$result = `$null
try {
    `$result = Add-IntuneWin32App @args -Verbose
} catch {
    Write-Host ("Warning: upload with optional metadata failed; retrying base upload. {0}" -f `$_.Exception.Message) -ForegroundColor Yellow
    `$retryArgs = @{}
    foreach (`$k in `$args.Keys) { `$retryArgs[`$k] = `$args[`$k] }
    foreach (`$k in `$optionalMetaParamNames) {
        if (`$retryArgs.ContainsKey(`$k)) { `$retryArgs.Remove(`$k) | Out-Null }
    }
    `$result = Add-IntuneWin32App @retryArgs -Verbose
}

`$appId = `$null
if (`$result) {
    foreach (`$prop in @('id','Id','appId','AppId','mobileAppId','MobileAppId')) {
        if (`$result.PSObject.Properties.Name -contains `$prop) {
            `$candidate = [string]`$result.`$prop
            if (![string]::IsNullOrWhiteSpace(`$candidate)) { `$appId = `$candidate; break }
        }
    }
}
`$uploadedFileName = [System.IO.Path]::GetFileName(`$intuneWinPath)
`$fileRenameApplied = `$false
`$mobileFileNamePatched = `$false
if (![string]::IsNullOrWhiteSpace(`$appId) -and (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
    try {
        # Patch mobile app-level filename (this is what the portal often displays in "Select file to update").
        `$mbody = @{ fileName = `$uploadedFileName } | ConvertTo-Json -Depth 3
        Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}" -f `$appId) -Body `$mbody -ContentType "application/json" | Out-Null
        # Also patch the win32LobApp typed endpoint.
        Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp" -f `$appId) -Body `$mbody -ContentType "application/json" | Out-Null
        `$mobileFileNamePatched = `$true
    } catch {
        Write-Host ("Warning: could not patch mobile app fileName to '{0}'. {1}" -f `$uploadedFileName, `$_.Exception.Message) -ForegroundColor Yellow
    }
    try {
        # Try to align Intune content file display name with the generated package filename.
        `$cvResp = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp/contentVersions" -f `$appId)
        `$cvs = @()
        if (`$cvResp -and `$cvResp.value) { `$cvs = @(`$cvResp.value) }
        if (`$cvs.Count -gt 0) {
            `$latestCv = `$cvs | Sort-Object { [int]`$_.id } -Descending | Select-Object -First 1
            if (`$latestCv -and `$latestCv.id) {
                `$filesResp = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp/contentVersions/{1}/files" -f `$appId, `$latestCv.id)
                `$files = @()
                if (`$filesResp -and `$filesResp.value) { `$files = @(`$filesResp.value) }
                if (`$files.Count -gt 0) {
                    foreach (`$targetFile in `$files) {
                        if (-not `$targetFile -or -not `$targetFile.id) { continue }
                        `$body = @{ name = `$uploadedFileName; fileName = `$uploadedFileName } | ConvertTo-Json -Depth 3
                        Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp/contentVersions/{1}/files/{2}" -f `$appId, `$latestCv.id, `$targetFile.id) -Body `$body -ContentType "application/json" | Out-Null
                        `$fileRenameApplied = `$true
                    }
                }
            }
        }
    } catch {
        Write-Host ("Warning: could not set uploaded file display name to '{0}'. {1}" -f `$uploadedFileName, `$_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`nUpload completed successfully." -ForegroundColor Green
if (![string]::IsNullOrWhiteSpace(`$appId)) {
    `$intuneUrl = "https://intune.microsoft.com/#view/Microsoft_Intune_Apps/SettingsMenu/0/appId/`$appId"
    `$graphUrl  = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/`$appId"
    Write-Host ("App ID       : {0}" -f `$appId) -ForegroundColor Green
    Write-Host ("Intune URL   : {0}" -f `$intuneUrl) -ForegroundColor Cyan
    Write-Host ("Graph URL    : {0}" -f `$graphUrl) -ForegroundColor Cyan
    if (`$mobileFileNamePatched) {
        Write-Host ("App fileName : {0}" -f `$uploadedFileName) -ForegroundColor Green
    }
    if (`$fileRenameApplied) {
        Write-Host ("Package name : {0}" -f `$uploadedFileName) -ForegroundColor Green
    }
} else {
    Write-Host "Upload succeeded but app ID could not be read from response." -ForegroundColor Yellow
}
Write-Host "`nResult details:" -ForegroundColor DarkGray
`$result | Format-List * | Out-Host
Stop-Transcript | Out-Null
"@
    try {
        [System.IO.File]::WriteAllText($tmpScript,$scriptText,[System.Text.Encoding]::UTF8)
        $p = Start-Process -FilePath $psPath -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$tmpScript) -WindowStyle Hidden -PassThru
        Write-DebugLog "INFO" ("IntuneUploadAssistantStarted | Script={0} | File={1} | Log={2} | Pid={3}" -f $tmpScript,$IntuneWinPath,$runLog,$p.Id)
        return [PSCustomObject]@{
            Started    = $true
            Process    = $p
            LogPath    = $runLog
            ScriptPath = $tmpScript
        }
    } catch {
        Write-DebugLog "ERROR" ("IntuneUploadAssistantStartFailed | {0}" -f $_.Exception.Message)
        return [PSCustomObject]@{
            Started = $false
            Error   = $_.Exception.Message
        }
    }
}

