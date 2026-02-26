# Changelog

## [Unreleased]
- Ongoing modularization and extraction cleanup.

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

