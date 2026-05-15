$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-ProjectRoot
Push-Location $root
try {
    docker compose ps
    Assert-LastExitCode 'docker compose ps'
} finally {
    Pop-Location
}
