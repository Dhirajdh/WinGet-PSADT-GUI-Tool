function Assert-WGPTPrerequisites {
    [CmdletBinding()]
    param()

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw 'PowerShell 5.1+ is required.'
    }
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'winget.exe not found.'
    }
}
