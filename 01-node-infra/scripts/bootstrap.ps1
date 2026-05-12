$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$paths = @(
    'config',
    'data',
    'logs',
    'artifacts',
    'reports'
)

foreach ($path in $paths) {
    New-Item -ItemType Directory -Force -Path (Join-Path $workspaceRoot $path) | Out-Null
}

$envExample = Join-Path $workspaceRoot '.env.example'
$envFile = Join-Path $workspaceRoot '.env'

if ((Test-Path $envExample) -and -not (Test-Path $envFile)) {
    Copy-Item -LiteralPath $envExample -Destination $envFile
}

Write-Host "Workspace ready: $workspaceRoot"
