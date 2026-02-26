# PowerShell Best Practices

## Parameter Validation
Use strict validation on public functions:

```powershell
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PackageId,

    [ValidateSet('Install','Uninstall','Repair')]
    [string]$DeploymentType = 'Install'
)
```

## Error Handling
Use explicit try/catch and rethrow actionable messages:

```powershell
try {
    # operation
}
catch {
    throw "Package generation failed: $($_.Exception.Message)"
}
finally {
    # cleanup/logging
}
```

## Logging
Keep a single logging path and format. Example:

```powershell
Write-WGPTLog -Level Info -Message "Starting package generation" -Context 'Packaging'
```

## Comment-Based Help
All exported functions should include:
- `.SYNOPSIS`
- `.DESCRIPTION`
- `.PARAMETER`
- `.EXAMPLE`
- `.NOTES`
