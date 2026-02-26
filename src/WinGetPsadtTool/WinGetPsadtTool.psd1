@{
    RootModule        = 'WinGetPsadtTool.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'f67e11dd-b19c-4ddf-b9f5-5a8a1e3efc42'
    Author            = 'WinGet-PSADT GUI Packaging Tool Contributors'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 Contributors'
    Description       = 'WinGet + PSADT GUI Packaging Tool module'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Start-WGPTGui',
        'New-WGPTPackage',
        'Publish-WGPTIntuneApp'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
