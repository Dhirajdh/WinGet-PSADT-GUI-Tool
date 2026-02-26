[CmdletBinding()]
param()

# Initialize module path / script pre-reqs
. (Join-Path $PSScriptRoot 'src\Core\Initialize.ps1')

# Launch full GUI host (migrated from root monolith into src/GUI)
. (Join-Path $PSScriptRoot 'src\GUI\MainHost.ps1')
