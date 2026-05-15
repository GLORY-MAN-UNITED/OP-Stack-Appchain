$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-ProjectRoot
Push-Location $root
try {
    docker compose up -d
    Assert-LastExitCode 'docker compose up'
} finally {
    Pop-Location
}
