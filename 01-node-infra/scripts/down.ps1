$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-ProjectRoot
Push-Location $root
try {
    docker compose down
    Assert-LastExitCode 'docker compose down'
} finally {
    Pop-Location
}
