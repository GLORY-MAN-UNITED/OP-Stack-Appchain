param(
    [string]$Service = ''
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-ProjectRoot
Push-Location $root
try {
    if ([string]::IsNullOrWhiteSpace($Service)) {
        docker compose logs -f
    } else {
        docker compose logs -f $Service
    }
    Assert-LastExitCode 'docker compose logs'
} finally {
    Pop-Location
}
