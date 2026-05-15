param(
    [switch]$SkipApply,
    [switch]$ForceGethInit,
    [switch]$Reset
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

function Get-LegacyOpDeployerBinary {
    $root = Get-ProjectRoot
    Join-Path $root '.tools\op-deployer-0.6.0-rc.2-linux\op-deployer-0.6.0-rc.2-linux-amd64\op-deployer'
}

function Ensure-OpDeployerRunnerImage {
    $root = Get-ProjectRoot
    $image = 'op-stack-op-deployer-runner:local'
    $dockerfile = Join-Path $root 'docker\op-deployer-runner.Dockerfile'

    cmd /c "docker image inspect $image >nul 2>nul"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Building $image for op-deployer TLS support..."
        & docker build -t $image -f $dockerfile $root
        Assert-LastExitCode 'docker build op-deployer runner'
    }

    return $image
}

function Invoke-LegacyOpDeployer {
    param(
        [string[]]$Arguments,
        [switch]$Capture
    )

    $root = Get-ProjectRoot
    $deployerDir = Join-Path $root 'deployer'
    $binary = Get-LegacyOpDeployerBinary

    if (-not (Test-Path $binary)) {
        throw "Missing op-deployer v0.6.0-rc.2 binary. Run scripts/download-op-deployer.ps1 first."
    }

    $toolDir = Split-Path -Parent $binary
    $deployerDir = (Resolve-Path $deployerDir).Path
    $runnerImage = Ensure-OpDeployerRunnerImage
    $dockerArgs = @(
        'run',
        '--rm',
        '-v', "${toolDir}:/tool:ro",
        '-v', "${deployerDir}:/workspace",
        '-w', '/workspace',
        $runnerImage,
        '/tool/op-deployer'
    ) + $Arguments

    if ($Capture) {
        $output = & docker @dockerArgs
        if ($LASTEXITCODE -ne 0) {
            throw "op-deployer $($Arguments[0]) failed with exit code $LASTEXITCODE"
        }
        return ($output -join [Environment]::NewLine)
    }

    & docker @dockerArgs
    Assert-LastExitCode "op-deployer $($Arguments[0])"
}

function Test-DeploymentStateComplete {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    try {
        $state = Get-Content $Path -Raw | ConvertFrom-Json
        return (($null -ne $state.appliedIntent) -and ($null -ne $state.opChainDeployments) -and ($state.opChainDeployments.Count -gt 0))
    } catch {
        return $false
    }
}

function Remove-GeneratedWorkdir {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    $rootPath = (Resolve-Path (Get-ProjectRoot)).Path
    $resolved = (Resolve-Path $Path).Path
    if (-not $resolved.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to delete path outside project root: $resolved"
    }

    Remove-Item -LiteralPath $resolved -Recurse -Force
}

function Get-RoleAddress {
    param(
        [hashtable]$Settings,
        [string]$SettingName,
        [string]$DefaultAddress
    )

    $explicit = Get-Setting $Settings $SettingName
    if (-not [string]::IsNullOrWhiteSpace($explicit)) {
        return $explicit
    }

    return $DefaultAddress
}

$root = Get-ProjectRoot
$envFile = Join-Path $root '.env'
$deployerDir = Join-Path $root 'deployer'
$workdir = Join-Path $deployerDir '.deployer'
$intentFile = Join-Path $workdir 'intent.toml'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker CLI is not installed.'
}

cmd /c "docker info >nul 2>nul"
if ($LASTEXITCODE -ne 0) {
    throw 'Docker daemon is not running. Start Docker Desktop first.'
}

$settings = Read-EnvFile $envFile
Require-Settings $settings @('L1_RPC_URL', 'L1_BEACON_URL', 'PRIVATE_KEY', 'ADMIN_ADDRESS', 'L2_CHAIN_ID')

$chainId = Get-Setting $settings 'L2_CHAIN_ID'
$adminAddress = Get-Setting $settings 'ADMIN_ADDRESS'
$privateKey = Normalize-PrivateKey (Get-Setting $settings 'PRIVATE_KEY')
$batcherPrivateKey = Normalize-PrivateKey (Get-Setting $settings 'BATCHER_PRIVATE_KEY' 'PRIVATE_KEY')
$proposerPrivateKey = Normalize-PrivateKey (Get-Setting $settings 'PROPOSER_PRIVATE_KEY' 'PRIVATE_KEY')
$deployRpcUrl = Get-Setting $settings 'L1_DEPLOY_RPC_URL' 'L1_RPC_URL'

$roleValues = @{
    'baseFeeVaultRecipient'      = Get-RoleAddress $settings 'BASE_FEE_VAULT_RECIPIENT' $adminAddress
    'l1FeeVaultRecipient'        = Get-RoleAddress $settings 'L1_FEE_VAULT_RECIPIENT' $adminAddress
    'sequencerFeeVaultRecipient' = Get-RoleAddress $settings 'SEQUENCER_FEE_VAULT_RECIPIENT' $adminAddress
    'operatorFeeVaultRecipient'  = Get-RoleAddress $settings 'OPERATOR_FEE_VAULT_RECIPIENT' $adminAddress
    'chainFeesRecipient'         = Get-RoleAddress $settings 'CHAIN_FEES_RECIPIENT' $adminAddress
    'l1ProxyAdminOwner'          = Get-RoleAddress $settings 'L1_PROXY_ADMIN_OWNER' $adminAddress
    'l2ProxyAdminOwner'          = Get-RoleAddress $settings 'L2_PROXY_ADMIN_OWNER' $adminAddress
    'systemConfigOwner'          = Get-RoleAddress $settings 'SYSTEM_CONFIG_OWNER' $adminAddress
    'unsafeBlockSigner'          = Get-RoleAddress $settings 'UNSAFE_BLOCK_SIGNER' $adminAddress
    'batcher'                    = Get-RoleAddress $settings 'BATCHER_ADDRESS' $adminAddress
    'proposer'                   = Get-RoleAddress $settings 'PROPOSER_ADDRESS' $adminAddress
    'challenger'                 = Get-RoleAddress $settings 'CHALLENGER_ADDRESS' $adminAddress
}

$paths = @(
    'deployer',
    'deployer\address',
    'sequencer',
    'batcher',
    'proposer',
    'artifacts',
    'config',
    'data',
    'logs',
    'reports'
)

foreach ($path in $paths) {
    Ensure-Directory (Join-Path $root $path)
}

Set-Content -LiteralPath (Join-Path $root 'deployer\address\admin_address.txt') -Value ($adminAddress + [Environment]::NewLine) -Encoding ASCII

if ($Reset) {
    Remove-GeneratedWorkdir $workdir
}

if (-not (Test-Path $intentFile)) {
    Push-Location $deployerDir
    try {
        Invoke-LegacyOpDeployer @(
            'init',
            '--l1-chain-id', (Get-Setting $settings 'L1_CHAIN_ID' '' '11155111'),
            '--l2-chain-ids', $chainId,
            '--workdir', '.deployer',
            '--intent-type', 'standard-overrides'
        )
    } finally {
        Pop-Location
    }
}

Set-OrReplaceTomlValue -Path $intentFile -Key 'l1ChainID' -Value (Get-Setting $settings 'L1_CHAIN_ID' '' '11155111')
Set-OrReplaceTomlValue -Path $intentFile -Key 'fundDevAccounts' -Value (Get-Setting $settings 'FUND_DEV_ACCOUNTS' '' 'true')
Set-OrReplaceTomlValue -Path $intentFile -Key 'useInterop' -Value (Get-Setting $settings 'USE_INTEROP' '' 'false') -Optional
Set-OrReplaceTomlValue -Path $intentFile -Key 'id' -Value (Format-ChainIdHex32 $chainId) -StringValue

$opcmAddress = Get-Setting $settings 'OPCM_ADDRESS'
if (-not [string]::IsNullOrWhiteSpace($opcmAddress)) {
    Set-OrReplaceTomlValue -Path $intentFile -Key 'opcmAddress' -Value $opcmAddress -StringValue -Optional
}

$l1ContractsLocator = Get-Setting $settings 'L1_CONTRACTS_LOCATOR'
if (-not [string]::IsNullOrWhiteSpace($l1ContractsLocator)) {
    Set-OrReplaceTomlValue -Path $intentFile -Key 'l1ContractsLocator' -Value $l1ContractsLocator -StringValue
}

$l2ContractsLocator = Get-Setting $settings 'L2_CONTRACTS_LOCATOR'
if (-not [string]::IsNullOrWhiteSpace($l2ContractsLocator)) {
    Set-OrReplaceTomlValue -Path $intentFile -Key 'l2ContractsLocator' -Value $l2ContractsLocator -StringValue
}

foreach ($entry in $roleValues.GetEnumerator()) {
    Set-OrReplaceTomlValue -Path $intentFile -Key $entry.Key -Value $entry.Value -StringValue -Optional
}

if ($SkipApply) {
    Write-Host "Intent prepared at $intentFile"
    return
}

Push-Location $deployerDir
try {
    if (Test-DeploymentStateComplete (Join-Path $workdir 'state.json')) {
        Write-Host 'Existing applied deployment state found; skipping L1 deployment transaction.'
    } else {
        Invoke-LegacyOpDeployer @(
            'apply',
            '--workdir', '.deployer',
            '--l1-rpc-url', $deployRpcUrl,
            '--private-key', $privateKey
        )
    }

    $l2ChainIdHex = Format-ChainIdHex32 $chainId
    $genesisJson = Invoke-LegacyOpDeployer @('inspect', 'genesis', '--workdir', '.deployer', $l2ChainIdHex) -Capture
    $rollupJson = Invoke-LegacyOpDeployer @('inspect', 'rollup', '--workdir', '.deployer', $l2ChainIdHex) -Capture

    Set-Content -LiteralPath (Join-Path $workdir 'genesis.json') -Value ($genesisJson + [Environment]::NewLine) -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $workdir 'rollup.json') -Value ($rollupJson + [Environment]::NewLine) -Encoding ASCII
} finally {
    Pop-Location
}

$genesisPath = Join-Path $workdir 'genesis.json'
$rollupPath = Join-Path $workdir 'rollup.json'
$statePath = Join-Path $workdir 'state.json'

foreach ($requiredFile in @($genesisPath, $rollupPath, $statePath)) {
    if (-not (Test-Path $requiredFile)) {
        throw "Missing generated file: $requiredFile"
    }
}

Copy-Item -LiteralPath $genesisPath -Destination (Join-Path $root 'sequencer\genesis.json') -Force
Copy-Item -LiteralPath $rollupPath -Destination (Join-Path $root 'sequencer\rollup.json') -Force
Copy-Item -LiteralPath $statePath -Destination (Join-Path $root 'batcher\state.json') -Force
Copy-Item -LiteralPath $statePath -Destination (Join-Path $root 'proposer\state.json') -Force

$jwtPath = Join-Path $root 'sequencer\jwt.txt'
if (-not (Test-Path $jwtPath)) {
    Set-Content -LiteralPath $jwtPath -Value ((New-HexSecret) + [Environment]::NewLine) -Encoding ASCII
}

$state = Get-Content $statePath -Raw | ConvertFrom-Json
$deployment = $state.opChainDeployments[0]
$gameFactory = $deployment.DisputeGameFactoryProxy
if ([string]::IsNullOrWhiteSpace($gameFactory)) {
    throw 'Could not determine DisputeGameFactoryProxy from state.json'
}

Write-KeyValueFile -Path (Join-Path $root 'batcher\.env.generated') -Values @{
    'OP_BATCHER_L1_ETH_RPC'                     = Get-Setting $settings 'L1_RPC_URL'
    'OP_BATCHER_PRIVATE_KEY'                    = $batcherPrivateKey
    'OP_BATCHER_L2_ETH_RPC'                     = 'http://op-geth:8545'
    'OP_BATCHER_ROLLUP_RPC'                     = 'http://op-node:8547'
    'OP_BATCHER_POLL_INTERVAL'                  = Get-Setting $settings 'OP_BATCHER_POLL_INTERVAL' '' '1s'
    'OP_BATCHER_SUB_SAFETY_MARGIN'              = Get-Setting $settings 'OP_BATCHER_SUB_SAFETY_MARGIN' '' '6'
    'OP_BATCHER_NUM_CONFIRMATIONS'              = Get-Setting $settings 'OP_BATCHER_NUM_CONFIRMATIONS' '' '1'
    'OP_BATCHER_SAFE_ABORT_NONCE_TOO_LOW_COUNT' = Get-Setting $settings 'OP_BATCHER_SAFE_ABORT_NONCE_TOO_LOW_COUNT' '' '3'
    'OP_BATCHER_MAX_CHANNEL_DURATION'           = Get-Setting $settings 'OP_BATCHER_MAX_CHANNEL_DURATION' '' '1'
    'OP_BATCHER_DATA_AVAILABILITY_TYPE'         = Get-Setting $settings 'OP_BATCHER_DATA_AVAILABILITY_TYPE' '' 'calldata'
    'OP_BATCHER_THROTTLE_UNSAFE_DA_BYTES_LOWER_THRESHOLD' = Get-Setting $settings 'OP_BATCHER_THROTTLE_UNSAFE_DA_BYTES_LOWER_THRESHOLD' '' '0'
    'OP_BATCHER_RPC_PORT'                       = Get-Setting $settings 'BATCHER_RPC_PORT' '' '8548'
}

Write-KeyValueFile -Path (Join-Path $root 'proposer\.env.generated') -Values @{
    'OP_PROPOSER_L1_ETH_RPC'           = Get-Setting $settings 'L1_RPC_URL'
    'OP_PROPOSER_ROLLUP_RPC'           = 'http://op-node:8547'
    'OP_PROPOSER_GAME_FACTORY_ADDRESS' = $gameFactory
    'OP_PROPOSER_PRIVATE_KEY'          = $proposerPrivateKey
    'OP_PROPOSER_PROPOSAL_INTERVAL'    = Get-Setting $settings 'OP_PROPOSER_PROPOSAL_INTERVAL' '' '3600s'
    'OP_PROPOSER_GAME_TYPE'            = Get-Setting $settings 'OP_PROPOSER_GAME_TYPE' '' '0'
    'OP_PROPOSER_POLL_INTERVAL'        = Get-Setting $settings 'OP_PROPOSER_POLL_INTERVAL' '' '20s'
    'OP_PROPOSER_ALLOW_NON_FINALIZED'  = Get-Setting $settings 'OP_PROPOSER_ALLOW_NON_FINALIZED' '' 'true'
    'OP_PROPOSER_WAIT_NODE_SYNC'       = Get-Setting $settings 'OP_PROPOSER_WAIT_NODE_SYNC' '' 'true'
}

$chainDataPath = Join-Path $root 'sequencer\op-geth-data\geth\chaindata'
if ($ForceGethInit -or -not (Test-Path $chainDataPath)) {
    $sequencerDir = (Resolve-Path (Join-Path $root 'sequencer')).Path
    $opGethArgs = @(
        'run',
        '--rm',
        '-v', "${sequencerDir}:/workspace",
        '-w', '/workspace',
        (Get-Setting $settings 'OP_GETH_IMAGE'),
        'init',
        '--datadir=./op-geth-data',
        '--state.scheme=hash',
        './genesis.json'
    )
    & docker @opGethArgs
    Assert-LastExitCode 'op-geth init'
}

Write-Host 'Rollup setup complete.'
