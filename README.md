# WinGet-PSADT GUI Packaging Tool

WinGet + PSAppDeployToolkit packaging GUI for IT professionals.  
Build standardized Win32 app packages, generate `.intunewin`, and publish to Intune with enterprise-safe defaults.

## Features
- WinGet package search and metadata discovery.
- PSAppDeployToolkit package scaffolding and script configuration.
- Function/parameter-driven configure experience by phase.
- `.intunewin` generation and Intune upload workflows.
- Detection rule authoring with JSON persistence.
- Live output and progress visibility for major operations.

## Requirements
- Windows 10/11
- Windows PowerShell 5.1 (Desktop)
- WinGet installed and available in `PATH`
- PSAppDeployToolkit available on the machine
- Microsoft Win32 Content Prep Tool (`IntuneWinAppUtil.exe`) manually placed in `Tools/`

Official Microsoft link for Win32 Content Prep Tool:
- https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

PSAppDeployToolkit installation reference:
- https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.Tools

## Post-Download Unblock Step
If you downloaded this project as ZIP, unblock scripts once after extraction to avoid repeated PowerShell security prompts:

```powershell
Get-ChildItem -Recurse -File | Unblock-File
```

## Quick Start`r`nPreferred (avoids repeated script trust prompts on ZIP downloads):`r`n```bat`r`n.\\Start-WinGetPsadtTool.cmd`r`n``` `r`n`r`nPowerShell entry (advanced/manual):`r`n```powershell`r`npowershell.exe -ExecutionPolicy Bypass -File .\\app\\Start-WinGetPsadtTool.ps1`r`n```

## Module Usage
```powershell
Import-Module .\src\WinGetPsadtTool\WinGetPsadtTool.psd1 -Force
Start-WGPTGui
```

## Repository Structure
```text
.
|- app/
|  \- Start-WinGetPsadtTool.ps1
|- src/WinGetPsadtTool/
|  |- Public/
|  |- Private/
|  |- WinGetPsadtTool.psm1
|  \- WinGetPsadtTool.psd1
|- assets/
|- Templates/
|- docs/
|- tests/
|- Tools/       # local dependency drop path only (not redistributed)
|- Packages/    # local generated package work area
|- Output/      # local generated .intunewin output
\- Logs/        # local runtime logs
```

## What Must Not Be Committed
- `Tools/` binaries (`IntuneWinAppUtil.exe`, DLLs, other executables)
- `Packages/`, `Output/`, `Logs/`
- installers and downloaded content
- `.intunewin`, archives, temp files
- secrets, keys, certificates

See `.gitignore` and `THIRD_PARTY_NOTICES.md`.

## Open-Source Compliance
- License: MIT (`LICENSE`)
- Changelog format: Keep a Changelog (`CHANGELOG.md`)
- Security reporting: `SECURITY.md`
- Contribution process: `CONTRIBUTING.md`

## Versioning
This project follows Semantic Versioning (`MAJOR.MINOR.PATCH`).

Recommended release flow:
1. Feature/fix merged to `main`
2. Update `CHANGELOG.md`
3. Tag release (`vX.Y.Z`)
4. Publish GitHub Release notes

## Third-Party Notice
This repository **does not redistribute** proprietary or third-party binaries/installers.  
Users must acquire and use those artifacts under their own licenses.

Details: `THIRD_PARTY_NOTICES.md`.

## Prerequisite Placement
See docs/prerequisites.md for exact folder-by-folder setup before first run.

## Product Overview
**WinGet-PSADT GUI Packaging Tool** is built for IT professionals who need repeatable, low-friction Win32 app packaging.

It provides a single operational surface for:
- application discovery from WinGet
- PSAppDeployToolkit-based packaging
- configure-by-phase script authoring
- `.intunewin` generation
- Intune upload workflows

## PSADT Function Categories in UI
The Configure panel organizes PSADT functions into practical categories to improve discoverability and reduce scripting errors:
- User Interface
- Registry
- File System
- Shortcuts
- Services
- User Context / Profiles
- Environment / System
- Configuration / INI
- Logging
- Security / Permissions
- Application Detection / Management
- Browser Extensions
- Process Execution
- MSI / MSP / MST
- Core Toolkit Engine

## Screenshots
> Add screenshots to `assets/screenshots/` using filenames in `assets/screenshots/README.md`.

### Search Results
![Search Results](assets/screenshots/01-search-results.png)

### Package Information
![Package Information](assets/screenshots/02-package-info.png)

### Configure Panel
![Configure Panel](assets/screenshots/03-configure-panel.png)

### PSADT Function Categories
![PSADT Function Categories](assets/screenshots/04-function-categories.png)

### Generate and Upload
![Generate and Upload](assets/screenshots/05-generate-upload.png)



