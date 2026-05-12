$ErrorActionPreference = 'Stop'

$tools = @(
    'git',
    'docker',
    'go',
    'node'
)

foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "[ok] $tool"
    } else {
        Write-Host "[missing] $tool"
    }
}

try {
    docker compose version | Out-Null
    Write-Host '[ok] docker compose'
} catch {
    Write-Host '[missing] docker compose'
}
