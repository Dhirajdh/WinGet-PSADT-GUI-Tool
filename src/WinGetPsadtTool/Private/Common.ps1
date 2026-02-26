function Get-WGPTRepoRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

function Invoke-WGPTLegacyScript {
    [CmdletBinding()]
    param(
        [string[]]$ArgumentList
    )

    $repoRoot = Get-WGPTRepoRoot
    $legacyScript = Join-Path $repoRoot 'WinGet-PSADT GUI Tool.ps1'
    if (-not (Test-Path $legacyScript -PathType Leaf)) {
        throw "Legacy script not found: $legacyScript"
    }

    & $legacyScript @ArgumentList
}
