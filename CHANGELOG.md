# Changelog

## [Unreleased]
- 

## [1.1.0] - 2026-02-26
### Changed
- Replaced legacy runtime layout with modular `src/` architecture.
- Switched launcher to `WinGet-PSADT-GUI.ps1` with GUI host at `src/GUI/MainHost.ps1`.
- Added `Start-WinGetPsadtTool.cmd` to unblock local files then start app.
- Fixed path resolution so `Packages`, `Output`, and `Logs` are created at repository root.
- Updated CI workflow to validate new modular layout (`WinGet-PSADT-GUI.ps1` + `src/**/*.ps1`).

### Fixed
- Restored README front-page screenshot rendering.
- Restored `assets/screenshots/*` files removed during repo replacement.

## [1.0.0] - 2026-02-26
### Added
- Introduced `src/` modular structure with ordered layering:
  - Core -> Validation -> Packaging -> Intune -> GUI
- Extracted packaging helpers:
  - `New-PSADTTemplateSafe`
  - `Normalize-PSADTTemplateSections`
  - AppDetails/SAIW read-write functions
- Extracted Intune upload helper:
  - `Start-IntuneUploadAssistant`
- Added GUI action wrappers in `src/GUI/MainWindow.ps1`.
- Added dedicated GUI modules for Configure/AppDetails.
- Added migration bootstrap script `WinGet-PSADT-GUI.ps1`.
