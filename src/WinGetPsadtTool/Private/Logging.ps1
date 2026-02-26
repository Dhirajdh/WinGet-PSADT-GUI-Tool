$script:WGPTLogPath = $null

function Initialize-WGPTLogging {
    [CmdletBinding()]
    param()

    $repo = Get-WGPTRepoRoot
    $logDir = Join-Path $repo 'Logs'
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:WGPTLogPath = Join-Path $logDir ("module_{0}.log" -f (Get-Date -Format 'yyyyMMdd'))
}

function Write-WGPTLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info','Warn','Error','Debug')]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $script:WGPTLogPath) { Initialize-WGPTLogging }
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Level.ToUpperInvariant(), $Message
    Add-Content -Path $script:WGPTLogPath -Value $line -Encoding UTF8
}
