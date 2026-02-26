function Invoke-DownloadAction {
    Show-Progress
    try {
        $selected = $ResultsGrid.SelectedItem
        if (!$selected) {
            Hide-Progress
            Show-Msg("Select an application from the list first.",
                "No Selection",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null; return
        }
        if ([string]::IsNullOrWhiteSpace($selected.ID) -or $selected.ID -eq "N/A") {
            Hide-Progress
            Show-Msg("Invalid package ID. Select a different result.",
                "Invalid Package",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
        }
        $ctx = Get-PackageContext $selected
        $safeName    = Get-SafeName $selected.Name
        $packageRoot = $ctx.PackageRoot
        $filesFolder = $ctx.FilesFolder
        Show-LiveOutput
        Append-LiveOutput "Download requested: $($selected.Name) [$($selected.ID)]"
        Append-LiveOutput "Checking PSADT module..."
        Append-LiveOutput "Resolving package version..."
        Write-DebugLog "INFO" ("DownloadClick | App={0} | Id={1} | SafeName={2}" -f $selected.Name,$selected.ID,$safeName)
        $resolvedVersion = Resolve-WingetPackageVersion -PackageId $selected.ID -GridVersion $selected.Version
        $Global:SelectedAppName = $selected.Name
        $Global:SelectedVersion = $resolvedVersion
        Append-LiveOutput "Resolved version: $resolvedVersion"
        if ($ctx -and $ctx.HasInstaller) {
            $Global:SelectedPackage = $ctx.PackageRoot
            Append-LiveOutput "Existing package detected: $($ctx.PackageRoot)"
            Append-LiveOutput "Existing installer: $($ctx.Installer.Name)"
            Set-Status "Using existing package for $($selected.Name) (download skipped)" "#10B981"
            Show-Msg(
                "Package already exists.`n`nUsing existing installer:`n$($ctx.Installer.FullName)`n`nDownload skipped.",
                "Existing Package",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
            Hide-Progress
            return
        }
        $winget = Get-WingetPath
        if (!$winget) {
            Hide-Progress
            Show-Msg("winget.exe not found.","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null; return
        }
        if (!(Ensure-PSADTModule)) { Hide-Progress; return }

        Set-Status "Creating PSADT v4 template for '$safeName'... (this can take a while)" "#3B82F6"
        Show-Progress
        Append-LiveOutput "Step 1/3: Preparing PSADT package workspace..."
        Append-LiveOutput "Package root: $packageRoot"
        $expectedDirs = @(
            $packageRoot,
            (Join-Path $packageRoot "Assets"),
            (Join-Path $packageRoot "Config"),
            (Join-Path $packageRoot "Files"),
            (Join-Path $packageRoot "Output"),
            (Join-Path $packageRoot "PSAppDeployToolkit"),
            (Join-Path $packageRoot "PSAppDeployToolkit.Extensions"),
            (Join-Path $packageRoot "Strings"),
            (Join-Path $packageRoot "SupportFiles")
        )
        Append-LiveOutput "Checking PSADT folder structure..."
        foreach ($d in $expectedDirs) {
            if (Test-Path $d) { Append-LiveOutput ("[exists]  {0}" -f $d) }
            else { Append-LiveOutput ("[pending] {0}" -f $d) }
        }
        Append-LiveOutput "Creating PSADT template: $safeName"
        Append-LiveOutput "Running New-ADTTemplate in background host (please wait)..."

        try {
            $tpl = New-PSADTTemplateSafe -Destination $Global:PackageRoot -Name $safeName -Force $true
            if ($tpl) {
                Append-LiveOutput ("Template command exit code: {0}" -f $tpl.ExitCode)
                if ($tpl.Output) { Append-LiveOutput ("Template output: {0}" -f (Get-CleanErrorText $tpl.Output)) }
            }
            if ($tpl.ExitCode -ne 0) {
                $detail = if ([string]::IsNullOrWhiteSpace($tpl.Output)) { "Unknown template creation error. ExitCode=$($tpl.ExitCode)" } else { Get-CleanErrorText $tpl.Output }
                throw $detail
            }
            Append-LiveOutput "Verifying created PSADT folders..."
            foreach ($d in $expectedDirs) {
                if (Test-Path $d) { Append-LiveOutput ("[ready]   {0}" -f $d) }
                else { Append-LiveOutput ("[missing] {0}" -f $d) }
            }
            Write-DebugLog "INFO" ("TemplateReady | PackageRoot={0}" -f $packageRoot)
            Set-Status "Template created. Starting download..." "#3B82F6"
            Append-LiveOutput "Step 2/3: Template ready."
            Append-LiveOutput "Template ready: $packageRoot"
        } catch {
            Write-DebugLog "ERROR" ("TemplateCreateFailed | App={0} | {1}" -f $selected.Name,$_.Exception.Message)
            Append-LiveOutput "Template creation failed: $($_.Exception.Message)"
            Hide-Progress
            Set-Status "Template creation failed: $($_.Exception.Message)" "#EF4444"
            Show-Msg("Failed to create PSADT template:`n`n$($_.Exception.Message)",
                "Template Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
            return
        }

        if (!(Test-Path $filesFolder)) { New-Item -ItemType Directory -Path $filesFolder -Force | Out-Null }

        # Capture into script scope for timer closure
        $script:DL_AppName     = $selected.Name
        $script:DL_SafeName    = $safeName
        $script:DL_PackageRoot = $packageRoot
        $script:DL_FilesFolder = $filesFolder
        $script:DL_OutFile     = Join-Path $env:TEMP "psadt_dl_$([System.IO.Path]::GetRandomFileName()).txt"
        $script:DL_ErrFile     = Join-Path $env:TEMP "psadt_dl_$([System.IO.Path]::GetRandomFileName()).err.txt"
        $script:DL_LastLine    = 0
        $script:DL_LastErrLine = 0
        $script:DL_HasOutput   = $false
        $pkgId                 = $selected.ID.Trim()
        $script:DL_PkgId       = $pkgId

        # Stop any prior download timer/process to avoid overlap.
        try {
            if ($script:DownloadTimer) { $script:DownloadTimer.Stop() }
            if ($script:CurrentDownloadProcess -and !$script:CurrentDownloadProcess.HasExited) {
                $script:CurrentDownloadProcess.Kill()
            }
        } catch {}

        # Launch winget directly; avoid cmd.exe indirection which can break app aliases/quoting.
        $dlArgs = "download --id `"$pkgId`" --exact --source winget --download-directory `"$filesFolder`" --accept-package-agreements --accept-source-agreements --disable-interactivity"
        $script:CurrentDownloadProcess = Start-Process -FilePath $winget -ArgumentList $dlArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput $script:DL_OutFile -RedirectStandardError $script:DL_ErrFile
        $Global:CurrentProcess = $script:CurrentDownloadProcess
        Write-DebugLog "INFO" ("WingetDownloadStart | Id={0} | Pid={1} | FilesFolder={2}" -f $pkgId,$script:CurrentDownloadProcess.Id,$filesFolder)
        Append-LiveOutput "Starting winget download..."
        Append-LiveOutput ">> $winget $dlArgs"
        Append-LiveOutput "PID: $($script:CurrentDownloadProcess.Id)"
        Set-Status "Downloading $($selected.Name)..." "#3B82F6"

        $script:DownloadTimer          = New-Object System.Windows.Threading.DispatcherTimer
        $script:DownloadTimer.Interval = [TimeSpan]::FromMilliseconds(500)
        $script:DownloadTimer.Add_Tick({
            if (Test-Path $script:DL_OutFile) {
                try {
                    $all = [System.IO.File]::ReadAllLines($script:DL_OutFile,[System.Text.Encoding]::UTF8)
                    if ($all.Count -gt $script:DL_LastLine) {
                        $new = $all[$script:DL_LastLine..($all.Count-1)]
                        $script:DL_LastLine = $all.Count
                        foreach ($nl in $new) { Append-LiveOutput $nl; $script:DL_HasOutput = $true }
                    }
                } catch {}
            }
            if (Test-Path $script:DL_ErrFile) {
                try {
                    $errAll = [System.IO.File]::ReadAllLines($script:DL_ErrFile,[System.Text.Encoding]::UTF8)
                    if ($errAll.Count -gt $script:DL_LastErrLine) {
                        $errNew = $errAll[$script:DL_LastErrLine..($errAll.Count-1)]
                        $script:DL_LastErrLine = $errAll.Count
                        foreach ($el in $errNew) { Append-LiveOutput $el; $script:DL_HasOutput = $true }
                    }
                } catch {}
            }
            if ($script:CurrentDownloadProcess -and $script:CurrentDownloadProcess.HasExited) {
                $script:DownloadTimer.Stop()
                Hide-Progress
                try {
                    if (Test-Path $script:DL_OutFile) { Remove-Item $script:DL_OutFile -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $script:DL_ErrFile) { Remove-Item $script:DL_ErrFile -Force -ErrorAction SilentlyContinue }
                } catch {}

                # Some packages write files a moment after process exits; retry briefly.
                $installer = $null
                for ($attempt = 0; $attempt -lt 6 -and !$installer; $attempt++) {
                    if ($attempt -gt 0) { Start-Sleep -Milliseconds 400 }
                    $installer = Find-DownloadedInstaller $script:DL_FilesFolder
                }

                Hide-LiveOutput
                if (!$installer) {
                    $found = Get-ChildItem -Path $script:DL_FilesFolder -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 20
                    if ($found) {
                        $names = ($found | ForEach-Object { $_.FullName }) -join " ; "
                        Write-DebugLog "WARN" ("WingetDownloadNoInstallerFilesPresent | Id={0} | Files={1}" -f $script:DL_PkgId,$names)
                    }
                    if (Test-Path $script:DL_OutFile) {
                        try {
                            $tail = Get-Content -LiteralPath $script:DL_OutFile -Tail 20 -ErrorAction SilentlyContinue
                            if ($tail) { Write-DebugLog "WARN" ("WingetDownloadOutputTail | Id={0} | Tail={1}" -f $script:DL_PkgId,($tail -join " | ")) }
                        } catch {}
                    }
                    if (Test-Path $script:DL_ErrFile) {
                        try {
                            $errTail = Get-Content -LiteralPath $script:DL_ErrFile -Tail 20 -ErrorAction SilentlyContinue
                            if ($errTail) { Write-DebugLog "WARN" ("WingetDownloadErrorTail | Id={0} | Tail={1}" -f $script:DL_PkgId,($errTail -join " | ")) }
                        } catch {}
                    }
                    Write-DebugLog "WARN" ("WingetDownloadNoInstaller | Id={0} | FilesFolder={1}" -f $script:DL_PkgId,$script:DL_FilesFolder)
                    Set-Status "Download finished - no installer found in Files folder" "#EF4444"
                    Show-Msg(
                        "winget exited but no installer was found in:`n$($script:DL_FilesFolder)`n`nThis package may not support direct download.`nPlace the installer manually in the Files folder.",
                        "Download Issue",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
                    return
                }
                $Global:SelectedPackage = $script:DL_PackageRoot
                $Global:SelectedAppName = $script:DL_AppName
                Write-DebugLog "INFO" ("WingetDownloadComplete | Installer={0} | PackageRoot={1}" -f $installer.Name,$script:DL_PackageRoot)
                Set-Status "Downloaded: $($installer.Name)  |  Ready to Configure" "#10B981"
                Show-Msg(
                    "Download complete!`n`nApp       : $($script:DL_AppName)`nInstaller : $($installer.Name)`nSaved to  : $($script:DL_FilesFolder)`n`nClick Configure to set up the PSADT script.",
                    "Download Complete",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
            }
        })
        $script:DownloadTimer.Start()
    } catch {
        Write-DebugLog "ERROR" ("DownloadUnhandledException | {0}" -f $_.Exception.Message)
        Hide-Progress
        Hide-LiveOutput
        Set-Status "Download failed: $($_.Exception.Message)" "#EF4444"
        Show-Msg(
            "Download failed with an unexpected error:`n`n$($_.Exception.Message)",
            "Download Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
}

function Invoke-ConfigureAction {
    Show-ConfigureWindow
}

function Invoke-GenerateAction {
    Show-Progress
    $selected = $ResultsGrid.SelectedItem
    $ctx = Get-PackageContext $selected
    if (!$ctx -or !$ctx.HasPackage) {
        Hide-Progress
        Show-Msg("Download and Configure a package first.",
            "No Package",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
    }
    $Global:SelectedPackage = $ctx.PackageRoot
    if (!$Global:SelectedAppName) { $Global:SelectedAppName = $ctx.AppName }
    $Global:SelectedVersion = Resolve-BestAppVersion -SelectedItem $selected -Context $ctx
    $scriptPath   = $ctx.ScriptPath
    $outputFolder = $Global:OutputRoot

    if (!(Test-Path $scriptPath)) {
        Hide-Progress
        Show-Msg("Invoke-AppDeployToolkit.ps1 not found. Click Configure first.",
            "Not Configured",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
    }
    if (!(Test-Path $Global:IntuneUtil)) {
        Hide-Progress
        $r = Show-Msg(
            "IntuneWinAppUtil.exe not found at:`n$($Global:IntuneUtil)`n`nPlace the tool in the Tools\ folder.`n`nOpen download page?",
            "Tool Not Found",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($r -eq "Yes") { Start-Process "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases" }
        return
    }

    if (!(Test-Path $outputFolder)) { New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null }
    $script:GEN_OutputFolder  = $outputFolder
    $script:GEN_SelectedPkg   = $Global:SelectedPackage
    $script:GEN_TargetName    = Get-IntuneWinOutputName $Global:SelectedAppName $Global:SelectedVersion
    Write-DebugLog "INFO" ("GenerateClick | PackageRoot={0} | Script={1}" -f $Global:SelectedPackage,$scriptPath)

    Set-Status "Packaging .intunewin - please wait..." "#3B82F6"
    Show-Progress
    Show-LiveOutput
    Append-LiveOutput "Generate requested for package: $($Global:SelectedPackage)"
    Append-LiveOutput "Using output folder: $outputFolder"
    Append-LiveOutput "Target output name: $($script:GEN_TargetName)"

    try {
        $args2 = "-c `"$($script:GEN_SelectedPkg)`" -s `"$scriptPath`" -o `"$outputFolder`" -q"
        $script:GEN_Process = Start-Process -FilePath $Global:IntuneUtil -ArgumentList $args2 -PassThru -WindowStyle Hidden
        $Global:CurrentProcess = $script:GEN_Process
        Write-DebugLog "INFO" ("GenerateStart | Pid={0} | Args={1}" -f $script:GEN_Process.Id,$args2)
        Append-LiveOutput ">> $($Global:IntuneUtil) $args2"
        Append-LiveOutput "PID: $($script:GEN_Process.Id)"

        $script:GenTimer          = New-Object System.Windows.Threading.DispatcherTimer
        $script:GenTimer.Interval = [TimeSpan]::FromMilliseconds(800)
        $script:GenTimer.Add_Tick({
            if ($script:GEN_Process -and $script:GEN_Process.HasExited) {
                $script:GenTimer.Stop(); Hide-Progress
                Append-LiveOutput "IntuneWinAppUtil exited."
                $pkg = Get-ChildItem $script:GEN_OutputFolder -Filter "*.intunewin" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($pkg) {
                    $finalPkg = $pkg
                    $targetPath = Join-Path $script:GEN_OutputFolder $script:GEN_TargetName
                    if ($pkg.Name -ne $script:GEN_TargetName) {
                        try {
                            if (Test-Path $targetPath) { Remove-Item -LiteralPath $targetPath -Force -ErrorAction SilentlyContinue }
                            Rename-Item -LiteralPath $pkg.FullName -NewName $script:GEN_TargetName -Force
                            $finalPkg = Get-Item -LiteralPath $targetPath -ErrorAction SilentlyContinue
                            if (!$finalPkg) { $finalPkg = Get-Item -LiteralPath (Join-Path $script:GEN_OutputFolder $script:GEN_TargetName) -ErrorAction SilentlyContinue }
                            if ($finalPkg) {
                                Append-LiveOutput "Renamed output: $($finalPkg.Name)"
                            }
                        } catch {
                            Write-DebugLog "WARN" ("GenerateRenameFailed | From={0} | To={1} | {2}" -f $pkg.Name,$script:GEN_TargetName,$_.Exception.Message)
                            Append-LiveOutput "Rename failed, keeping: $($pkg.Name)"
                            $finalPkg = $pkg
                        }
                    }
                    Append-LiveOutput "Keeping package as generated by IntuneWinAppUtil (no internal metadata rewrite)."
                    Write-DebugLog "INFO" ("GenerateComplete | File={0}" -f $pkg.FullName)
                    Set-Status "Package ready: $($finalPkg.Name)" "#10B981"
                    Hide-LiveOutput
                    $op = Show-Msg(
                        ".intunewin created!`n`nFile     : $($finalPkg.Name)`nSaved to : $($script:GEN_OutputFolder)`n`nOpen output folder?",
                        "Package Complete",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Information)
                    if (Test-MsgResult -Result $op -Target "Yes") {
                        try {
                            $folderPath = if ($finalPkg -and $finalPkg.DirectoryName) { [string]$finalPkg.DirectoryName } else { [string]$script:GEN_OutputFolder }
                            $filePath   = if ($finalPkg -and $finalPkg.FullName) { [string]$finalPkg.FullName } else { "" }

                            if (![string]::IsNullOrWhiteSpace($filePath) -and (Test-Path -LiteralPath $filePath)) {
                                Start-Process -FilePath "explorer.exe" -ArgumentList "/select,`"$filePath`"" | Out-Null
                            } elseif (![string]::IsNullOrWhiteSpace($folderPath) -and (Test-Path -LiteralPath $folderPath)) {
                                Start-Process -FilePath "explorer.exe" -ArgumentList "`"$folderPath`"" | Out-Null
                            }
                        } catch {
                            try {
                                if ($script:GEN_OutputFolder -and (Test-Path -LiteralPath $script:GEN_OutputFolder)) {
                                    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$($script:GEN_OutputFolder)`"" | Out-Null
                                }
                            } catch {}
                        }
                    }
                } else {
                    Write-DebugLog "WARN" ("GenerateCompleteNoOutput | OutputFolder={0}" -f $script:GEN_OutputFolder)
                    Append-LiveOutput "No .intunewin file found in output."
                    Set-Status ".intunewin not found after packaging - check IntuneWinAppUtil output" "#EF4444"
                    Show-Msg("Tool finished but no .intunewin found in:`n$($script:GEN_OutputFolder)",
                        "Package Issue",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
                }
            }
        })
        $script:GenTimer.Start()
    } catch {
        Write-DebugLog "ERROR" ("GenerateFailed | {0}" -f $_.Exception.Message)
        Append-LiveOutput "Generate failed: $($_.Exception.Message)"
        Hide-Progress; Set-Status "Packaging failed: $($_.Exception.Message)" "#EF4444"
        Show-Msg("Failed to run IntuneWinAppUtil:`n$($_.Exception.Message)",
            "Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
    }
}

function Invoke-UploadAction {
    Show-Progress
    $selected = $ResultsGrid.SelectedItem
    $ctx = Get-PackageContext $selected
    if (!$ctx -or !$ctx.HasPackage) {
        Hide-Progress
        Show-Msg("Download and configure a package first.",
            "No Package",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $Global:SelectedPackage = $ctx.PackageRoot
    if (!$Global:SelectedAppName) { $Global:SelectedAppName = $ctx.AppName }
    $Global:SelectedVersion = Resolve-BestAppVersion -SelectedItem $selected -Context $ctx

    $outputFolder = $Global:OutputRoot
    if (!(Test-Path $outputFolder)) {
        Hide-Progress
        Show-Msg("Output folder not found. Generate .intunewin first.",
            "No Output",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    $targetName = Get-IntuneWinOutputName $Global:SelectedAppName $Global:SelectedVersion
    $targetPath = Join-Path $outputFolder $targetName
    $pkg = $null
    $chooseMode = Show-Msg(
        "Choose upload file mode:`n`nYes = Use expected generated file`nNo = Browse and select .intunewin from Output folder`n`nExpected:`n$targetPath",
        "Upload File Selection",
        [System.Windows.MessageBoxButton]::YesNoCancel,
        [System.Windows.MessageBoxImage]::Question
    )
    if ((Test-MsgResult -Result $chooseMode -Target "Cancel") -or
        (Test-MsgResult -Result $chooseMode -Target "None")) {
        Hide-Progress
        return
    }
    if (Test-MsgResult -Result $chooseMode -Target "No") {
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Title = "Select .intunewin package"
        $ofd.Filter = "Intune Package (*.intunewin)|*.intunewin|All Files (*.*)|*.*"
        $ofd.Multiselect = $false
        if (Test-Path $outputFolder) { $ofd.InitialDirectory = $outputFolder }
        $ofd.FileName = $targetName
        $pick = $ofd.ShowDialog($Window)
        if ($pick -ne $true -or [string]::IsNullOrWhiteSpace($ofd.FileName) -or !(Test-Path $ofd.FileName)) {
            Hide-Progress
            return
        }
        $pkg = Get-Item -LiteralPath $ofd.FileName -ErrorAction SilentlyContinue
    } else {
        $pkg = if (Test-Path $targetPath) { Get-Item -LiteralPath $targetPath -ErrorAction SilentlyContinue } else { $null }
        if (!$pkg) {
            Hide-Progress
            Show-Msg("Expected package file not found:`n$targetPath`n`nClick Generate .intunewin first, or choose No to browse and select another file.",
                "No Package File",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
    }

    $defaultName = if ($ResultsGrid.SelectedItem -and $ResultsGrid.SelectedItem.Name) {
        [string]$ResultsGrid.SelectedItem.Name
    } else {
        [string]$ctx.AppName
    }

    Write-DebugLog "INFO" ("UploadClick | File={0}" -f $pkg.FullName)
    Set-Status "Launching Intune upload assistant..." "#3B82F6"
    Show-LiveOutput
    Append-LiveOutput "Upload requested: $($pkg.FullName)"
    Append-LiveOutput "Starting Intune upload assistant window..."

    $publisherDefault = "Unknown Publisher"
    $descDefault = if ($Global:SelectedVersion) { "$defaultName $($Global:SelectedVersion) uploaded by WinGet-PSADT GUI Tool" } else { "$defaultName uploaded by WinGet-PSADT GUI Tool" }
    $appVersionDefault = if ($Global:SelectedVersion) { [string]$Global:SelectedVersion } else { "" }
    $infoUrlDefault = ""
    $privacyUrlDefault = ""
    $developerDefault = ""
    $ownerDefault = ""
    $notesDefault = ""
    $det = Get-AppDetailsFromScript -ScriptPath (Join-Path $Global:SelectedPackage "Invoke-AppDeployToolkit.ps1") -AppName $defaultName -Version $Global:SelectedVersion
    if ($det.AppVendor) { $publisherDefault = $det.AppVendor }
    if ($det.AppVersion) { $descDefault = "$defaultName $($det.AppVersion) uploaded by WinGet-PSADT GUI Tool" }
    if ($det.AppVersion) { $appVersionDefault = [string]$det.AppVersion }
    if ($det.AppVendor) { $developerDefault = [string]$det.AppVendor; $ownerDefault = [string]$det.AppVendor }
    $pkgInfo = if ($selected -and $selected.ID) { Get-WingetPackageInfo -PackageId ([string]$selected.ID) } else { $null }
    if ($pkgInfo) {
        if ($pkgInfo.Publisher -and ($publisherDefault -eq "Unknown Publisher")) { $publisherDefault = [string]$pkgInfo.Publisher }
        if ($pkgInfo.Version -and [string]::IsNullOrWhiteSpace($appVersionDefault)) { $appVersionDefault = [string]$pkgInfo.Version }
        if ($pkgInfo.InformationUrl) { $infoUrlDefault = [string]$pkgInfo.InformationUrl }
        if ($pkgInfo.PrivacyUrl) { $privacyUrlDefault = [string]$pkgInfo.PrivacyUrl }
        if ($pkgInfo.Developer -and [string]::IsNullOrWhiteSpace($developerDefault)) { $developerDefault = [string]$pkgInfo.Developer }
        if ($pkgInfo.Owner -and [string]::IsNullOrWhiteSpace($ownerDefault)) { $ownerDefault = [string]$pkgInfo.Owner }
        if ($pkgInfo.Notes) { $notesDefault = [string]$pkgInfo.Notes }
    }
    if ([string]::IsNullOrWhiteSpace($developerDefault) -and $publisherDefault -and $publisherDefault -ne "Unknown Publisher") { $developerDefault = $publisherDefault }
    if ([string]::IsNullOrWhiteSpace($ownerDefault) -and $publisherDefault -and $publisherDefault -ne "Unknown Publisher") { $ownerDefault = $publisherDefault }
    $iconToUse = if ($det.AppIconPath -and (Test-Path $det.AppIconPath)) { $det.AppIconPath } else { Find-PackageIcon -PackageRoot $Global:SelectedPackage -FilesFolder (Join-Path $Global:SelectedPackage "Files") }
    $detCfg = Get-DetectionConfigForScript -ScriptPath (Join-Path $Global:SelectedPackage "Invoke-AppDeployToolkit.ps1") -AppName $defaultName -AppVersion $appVersionDefault
    $detNameRegexPreview = if ([string]::IsNullOrWhiteSpace([string]$detCfg.DetectionNameRegex)) { '^' + [regex]::Escape([string]$defaultName) + '(?:\s|$)' } else { [string]$detCfg.DetectionNameRegex }
    $detUseVersionPreview = if ([string]::IsNullOrWhiteSpace([string]$detCfg.DetectionUseVersion)) {
        -not [string]::IsNullOrWhiteSpace([string]$appVersionDefault)
    } else {
        [System.Convert]::ToBoolean([string]$detCfg.DetectionUseVersion)
    }
    $detVersionPreview = if ([string]::IsNullOrWhiteSpace([string]$detCfg.DetectionVersion)) { [string]$appVersionDefault } else { [string]$detCfg.DetectionVersion }
    $detRootsPreview = @()
    if (![string]::IsNullOrWhiteSpace([string]$detCfg.DetectionRegistryRoots)) {
        $detRootsPreview = @(([string]$detCfg.DetectionRegistryRoots) -split ';' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    if ($detRootsPreview.Count -eq 0) {
        $detRootsPreview = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    Append-LiveOutput "Detection rule preview:"
    Append-LiveOutput ("  NameRegex      : {0}" -f $detNameRegexPreview)
    Append-LiveOutput ("  UseVersion     : {0}" -f $detUseVersionPreview)
    Append-LiveOutput ("  Version        : {0}" -f $detVersionPreview)
    Append-LiveOutput ("  RegistryRoots  : {0}" -f ($detRootsPreview -join ';'))
    Append-LiveOutput "  Script logic   :"
    Append-LiveOutput "    `$roots = @(...)"
    Append-LiveOutput "    `$apps  = foreach (`$r in `$roots) { Get-ItemProperty -Path `$r -ErrorAction SilentlyContinue }"
    Append-LiveOutput ("    `$hits  = `$apps | Where-Object {{ `$_.DisplayName -and (`$_.DisplayName -match '{0}') }}" -f $detNameRegexPreview)
    if ($detUseVersionPreview -and ![string]::IsNullOrWhiteSpace($detVersionPreview)) {
        Append-LiveOutput ("    `$hits  = `$hits | Where-Object {{ [string]`$_.DisplayVersion -eq '{0}' }}" -f $detVersionPreview)
    }
    Append-LiveOutput "    if (`$hits) { exit 0 } else { exit 1 }"
    $ua = Start-IntuneUploadAssistant `
        -PackageRoot $Global:SelectedPackage `
        -IntuneWinPath $pkg.FullName `
        -DefaultDisplayName $defaultName `
        -DefaultPublisher $publisherDefault `
        -DefaultDescription $descDefault `
        -IconPath $iconToUse `
        -DefaultAppVersion $appVersionDefault `
        -DefaultInformationUrl $infoUrlDefault `
        -DefaultPrivacyUrl $privacyUrlDefault `
        -DefaultDeveloper $developerDefault `
        -DefaultOwner $ownerDefault `
        -DefaultNotes $notesDefault `
        -DetectionNameRegex ([string]$detCfg.DetectionNameRegex) `
        -DetectionUseVersion ([string]$detCfg.DetectionUseVersion) `
        -DetectionVersion ([string]$detCfg.DetectionVersion) `
        -DetectionRegistryRoots ([string]$detCfg.DetectionRegistryRoots)
    if ($ua -and $ua.Started -and $ua.Process) {
        $script:UP_Process = $ua.Process
        $script:UP_LogPath = $ua.LogPath
        $script:UP_LastLine = 0
        $Global:CurrentProcess = $script:UP_Process
        Show-Progress
        Set-Status "Uploading to Intune... complete auth in browser if prompted." "#3B82F6"
        Append-LiveOutput ("Upload process started (PID: {0})" -f $script:UP_Process.Id)
        Append-LiveOutput "Waiting for authentication and upload progress..."
        if ($script:UploadTimer) { try { $script:UploadTimer.Stop() } catch {} }
        $script:UploadTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:UploadTimer.Interval = [TimeSpan]::FromMilliseconds(900)
        $script:UploadTimer.Add_Tick({
            try {
                if ($script:UP_LogPath -and (Test-Path $script:UP_LogPath)) {
                    $all = [System.IO.File]::ReadAllLines($script:UP_LogPath,[System.Text.Encoding]::UTF8)
                    if ($all.Count -gt $script:UP_LastLine) {
                        $new = $all[$script:UP_LastLine..($all.Count-1)]
                        $script:UP_LastLine = $all.Count
                        foreach ($ln in $new) {
                            if (![string]::IsNullOrWhiteSpace($ln)) { Append-LiveOutput $ln }
                        }
                    }
                }
                if ($script:UP_Process -and $script:UP_Process.HasExited) {
                    $script:UploadTimer.Stop()
                    Hide-Progress
                    $code = $script:UP_Process.ExitCode
                    if ($code -eq 0) {
                        Set-Status "Intune upload completed successfully." "#10B981"
                        $intuneUrl = ""
                        $graphUrl = ""
                        if ($script:UP_LogPath -and (Test-Path $script:UP_LogPath)) {
                            try {
                                $tail = Get-Content -LiteralPath $script:UP_LogPath -Tail 200 -ErrorAction SilentlyContinue
                                $iu = $tail | Where-Object { $_ -match "Intune URL\s*:\s*" } | Select-Object -Last 1
                                $gu = $tail | Where-Object { $_ -match "Graph URL\s*:\s*" } | Select-Object -Last 1
                                if ($iu) { $intuneUrl = ($iu -replace '.*Intune URL\s*:\s*','').Trim() }
                                if ($gu) { $graphUrl = ($gu -replace '.*Graph URL\s*:\s*','').Trim() }
                            } catch {}
                        }
                        $msg = "Upload completed successfully."
                        if ($intuneUrl) { $msg += "`n`nIntune URL:`n$intuneUrl" }
                        if ($graphUrl) { $msg += "`n`nGraph URL:`n$graphUrl" }
                        Show-Msg($msg,"Upload Complete",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
                    } else {
                        Set-Status ("Intune upload failed (exit code {0}). Check logs." -f $code) "#EF4444"
                        Show-Msg("Upload failed (exit code $code).`n`nCheck Logs for details.","Upload Failed",
                            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
                    }
                }
            } catch {}
        })
        $script:UploadTimer.Start()
        Set-Status "Intune upload started. Follow browser sign-in if prompted." "#3B82F6"
    } else {
        Hide-Progress
        Append-LiveOutput "Failed to start upload assistant."
        Set-Status "Failed to start Intune upload assistant" "#EF4444"
        Show-Msg(
            "Could not start the Intune upload assistant.`n`n$($ua.Error)`n`nCheck Logs for details.",
            "Upload Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
}
