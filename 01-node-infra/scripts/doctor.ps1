$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-ProjectRoot
$envFile = Join-Path $root '.env'
$toolReport = @()
$tools = @('git', 'docker', 'node', 'go')

foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        $toolReport += "[ok] $tool"
    } else {
        $toolReport += "[missing] $tool"
    }
}

$dockerDaemon = $false
if (Get-Command docker -ErrorAction SilentlyContinue) {
    cmd /c "docker info >nul 2>nul"
    $dockerDaemon = ($LASTEXITCODE -eq 0)
}

if ($dockerDaemon) {
    $toolReport += '[ok] docker daemon'
} else {
    $toolReport += '[missing] docker daemon'
}

$setupOpDeployerPath = Join-Path $root '.tools\op-deployer-0.6.0-rc.2-linux\op-deployer-0.6.0-rc.2-linux-amd64\op-deployer'
if (Test-Path $setupOpDeployerPath) {
    $toolReport += '[ok] setup op-deployer v0.6.0-rc.2 binary'
} else {
    $toolReport += '[missing] setup op-deployer v0.6.0-rc.2 binary'
}

$windowsOpDeployerPath = Join-Path $root '.tools\op-deployer.exe'
if (Test-Path $windowsOpDeployerPath) {
    $toolReport += '[ok] optional Windows op-deployer binary'
} else {
    $toolReport += '[missing] optional Windows op-deployer binary'
}

$requiredSettings = @('L1_RPC_URL', 'L1_BEACON_URL', 'PRIVATE_KEY', 'ADMIN_ADDRESS')
if (Test-Path $envFile) {
    $settings = Read-EnvFile $envFile
    foreach ($key in $requiredSettings) {
        if ([string]::IsNullOrWhiteSpace((Get-Setting $settings $key))) {
            $toolReport += "[empty] $key"
        } else {
            $toolReport += "[set] $key"
        }
    }

    $privateKey = Get-Setting $settings 'PRIVATE_KEY'
    if (-not [string]::IsNullOrWhiteSpace($privateKey)) {
        if ((Normalize-PrivateKey $privateKey) -match '^[0-9a-fA-F]{64}$') {
            $toolReport += '[ok] PRIVATE_KEY format'
        } else {
            $toolReport += '[invalid] PRIVATE_KEY format'
        }
    }
} else {
    $toolReport += '[missing] .env'
}

$toolReport | ForEach-Object { Write-Host $_ }
