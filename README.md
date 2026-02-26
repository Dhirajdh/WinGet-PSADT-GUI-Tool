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

## Quick Start
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\app\Start-WinGetPsadtTool.ps1
```

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

