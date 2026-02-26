# Architecture

## Execution Model
This repository uses a compatibility-first modular shell over the production GUI script to avoid functional regression.

## Module Boundaries
- GUI host orchestration: `src/WinGetPsadtTool/Private/GuiHost.ps1`
- Packaging workflows: `src/WinGetPsadtTool/Private/PackageBuilder.ps1`
- Intune publishing workflows: `src/WinGetPsadtTool/Private/IntuneUploader.ps1`
- Logging primitives: `src/WinGetPsadtTool/Private/Logging.ps1`
- Input and safety checks: `src/WinGetPsadtTool/Private/Validation.ps1`
- Public surface: `src/WinGetPsadtTool/Public/*.ps1`

## Public Entry Points
- `Start-WGPTGui`
- `New-WGPTPackage`
- `Publish-WGPTIntuneApp`

## Import/Launch
```powershell
Import-Module .\src\WinGetPsadtTool\WinGetPsadtTool.psd1 -Force
Start-WGPTGui
```

## Migration Principle
Preserve runtime behavior first, then incrementally move logic from monolith to module-private functions with tests.
