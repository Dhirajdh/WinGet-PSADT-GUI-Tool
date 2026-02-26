# Contributing Guide

Thanks for contributing.

## Ground Rules
- Preserve current runtime behavior, GUI flow, and visual design unless change is explicitly requested.
- Keep PRs focused and small.
- Do not commit runtime/generated artifacts (`Logs/`, `Output/`, `Packages/`).
- Do not commit proprietary binaries or third-party installers.

## Development Setup
1. Clone the repo.
2. Open Windows PowerShell 5.1.
3. Launch app:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\app\Start-WinGetPsadtTool.ps1
   ```
4. Module test import:
   ```powershell
   Import-Module .\src\WinGetPsadtTool\WinGetPsadtTool.psd1 -Force
   Get-Command -Module WinGetPsadtTool
   ```

## Branching
- `main`: stable
- `feature/*`: new features
- `fix/*`: bug fixes
- `docs/*`: documentation-only changes

## Commit Convention
Use conventional commit style:
- `feat: ...`
- `fix: ...`
- `refactor: ...`
- `docs: ...`
- `chore: ...`

## Pull Request Checklist
- [ ] Scope is clear and minimal.
- [ ] Manual validation steps are included.
- [ ] No GUI regressions.
- [ ] No packaging/upload flow regressions.
- [ ] `CHANGELOG.md` updated (if user-facing change).
- [ ] No generated artifacts or proprietary binaries added.

## PowerShell Engineering Standards
- Public functions must include parameter validation (`ValidateSet`, `ValidateNotNullOrEmpty`, etc.).
- Use structured error handling (`try/catch/finally`) and clear terminating errors where needed.
- Route operational events through logging helpers.
- Keep exported commands documented via comment-based help.
