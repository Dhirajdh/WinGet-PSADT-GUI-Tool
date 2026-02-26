# Prerequisites and Folder Placement

This project intentionally does not redistribute proprietary binaries or third-party installers.

## Required Before First Run

1. Install Windows PowerShell 5.1 (Desktop).
2. Install WinGet.
3. Install PSAppDeployToolkit on the machine.
4. Download Microsoft Win32 Content Prep Tool (`IntuneWinAppUtil.exe`).

## Where to Place Prerequisites

- `Tools/`
  - Place: `IntuneWinAppUtil.exe`
  - Required for: `.intunewin` generation

- `Templates/PSADT/`
  - Keep as placeholder only in this repo.
  - Do not commit PSADT binaries/modules here.
  - Runtime template creation is handled via installed PSAppDeployToolkit (`New-ADTTemplate`).

- `Packages/`
  - Runtime working directory for generated package folders.
  - Do not commit contents.

- `Output/`
  - Runtime output for `.intunewin` files.
  - Do not commit contents.

- `Logs/`
  - Runtime logs.
  - Do not commit contents.

## Quick Verification

```powershell
Test-Path .\Tools\IntuneWinAppUtil.exe
Get-Command winget -ErrorAction SilentlyContinue
Get-Module -ListAvailable PSAppDeployToolkit
```

If all return successfully, the app can run end-to-end.
