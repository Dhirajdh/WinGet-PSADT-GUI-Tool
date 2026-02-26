# WinGet-PSADT-GUI-Tool

This workspace contains the modular migration of:
- `src/GUI/MainHost.ps1` (legacy monolith)

## Migration Status
The code is split under `src/` using the dependency order:
- `Core`
- `Validation`
- `Packaging`
- `Intune`
- `GUI`

## Extracted Modules
- `src/Packaging/PSADTTemplate.ps1`
  - `New-PSADTTemplateSafe`
  - `Normalize-PSADTTemplateSections`
- `src/Packaging/ScriptEditor.ps1`
  - `Get-AppDetailsFromScript`
  - `Save-AppDetailsToScript`
  - `Get-SAIWParamsFromScript`
  - `Save-SAIWParamsToScript`
- `src/Intune/Upload.ps1`
  - `Start-IntuneUploadAssistant`
- `src/GUI/MainWindow.ps1`
  - `Invoke-DownloadAction`
  - `Invoke-ConfigureAction`
  - `Invoke-GenerateAction`
  - `Invoke-UploadAction`
- `src/GUI/ConfigureWindow.ps1`
  - `Show-ConfigureWindow`
- `src/GUI/AppDetailsWindow.ps1`
  - `Show-AppDetailsWindow`

## Entry Points
- Legacy full script:
  - `src/GUI/MainHost.ps1`
- Migration bootstrap:
  - `WinGet-PSADT-GUI.ps1`

## Run
Preferred (auto-unblocks local files first):
```cmd
.\Start-WinGetPsadtTool.cmd
```

PowerShell entry:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\WinGet-PSADT-GUI.ps1
```

## Prerequisites`r`n- Windows PowerShell 5.1
- WinGet
- PSAppDeployToolkit.Tools: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.Tools
- Microsoft Win32 Content Prep Tool: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

## Notes
- No organization placeholders remain in README/CHANGELOG.
- Module files in `src/` parse successfully.





