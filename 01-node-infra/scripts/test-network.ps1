param(
    [int]$TimeoutSec = 8
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

function Invoke-L1Rpc {
    param(
        [string]$Url,
        [string]$Method,
        [object[]]$Params = @()
    )

    $body = @{
        jsonrpc = '2.0'
        id      = 1
        method  = $Method
        params  = $Params
    } | ConvertTo-Json -Compress

    Invoke-RestMethod -Method Post -Uri $Url -Body $body -ContentType 'application/json' -TimeoutSec $TimeoutSec
}

$root = Get-ProjectRoot
$envFile = Join-Path $root '.env'
$settings = Read-EnvFile $envFile
Require-Settings $settings @('L1_RPC_URL', 'L1_BEACON_URL', 'ADMIN_ADDRESS')

$ok = $true
$rpcUrl = Get-Setting $settings 'L1_RPC_URL'
$deployRpcUrl = Get-Setting $settings 'L1_DEPLOY_RPC_URL' 'L1_RPC_URL'
$beaconUrl = Get-Setting $settings 'L1_BEACON_URL'
$adminAddress = Get-Setting $settings 'ADMIN_ADDRESS'

try {
    $chainId = (Invoke-L1Rpc $rpcUrl 'eth_chainId').result
    $blockNumber = (Invoke-L1Rpc $rpcUrl 'eth_blockNumber').result
    $balanceHex = (Invoke-L1Rpc $rpcUrl 'eth_getBalance' @($adminAddress, 'latest')).result
    $balanceWei = [System.Numerics.BigInteger]::Parse($balanceHex.Substring(2), [System.Globalization.NumberStyles]::HexNumber)
    $balanceEth = [decimal]$balanceWei / 1000000000000000000

    if ($chainId -eq '0xaa36a7') {
        Write-Host "[ok] L1 RPC Sepolia chainId=$chainId block=$blockNumber balance=$('{0:N6}' -f $balanceEth) ETH"
    } else {
        Write-Host "[fail] L1 RPC returned non-Sepolia chainId=$chainId"
        $ok = $false
    }

    if ($balanceEth -lt 0.2) {
        Write-Host '[warn] Sepolia ETH balance is low. Deployment may fail from insufficient gas.'
    } elseif ($balanceEth -lt 2) {
        Write-Host '[warn] Official tutorials often recommend 2-3 Sepolia ETH. This may still work for a demo but is not guaranteed.'
    }
} catch {
    Write-Host "[fail] L1 RPC unreachable: $($_.Exception.Message)"
    $ok = $false
}

if ($deployRpcUrl -ne $rpcUrl) {
    try {
        $deployChainId = (Invoke-L1Rpc $deployRpcUrl 'eth_chainId').result
        if ($deployChainId -eq '0xaa36a7') {
            Write-Host "[ok] Deployment RPC Sepolia chainId=$deployChainId"
        } else {
            Write-Host "[fail] Deployment RPC returned non-Sepolia chainId=$deployChainId"
            $ok = $false
        }
    } catch {
        Write-Host "[fail] Deployment RPC unreachable: $($_.Exception.Message)"
        $ok = $false
    }
}

try {
    $response = Invoke-WebRequest -Uri ($beaconUrl.TrimEnd('/') + '/eth/v1/beacon/genesis') -TimeoutSec $TimeoutSec -UseBasicParsing
    Write-Host "[ok] L1 Beacon reachable status=$($response.StatusCode)"
} catch {
    Write-Host "[fail] L1 Beacon unreachable: $($_.Exception.Message)"
    Write-Host '[hint] If publicnode is blocked on campus Wi-Fi, use the Alchemy Sepolia Beacon endpoint from the same app key.'
    $ok = $false
}

try {
    $dockerVersion = docker info --format '{{.ServerVersion}}'
    Write-Host "[ok] Docker daemon version=$dockerVersion"
} catch {
    Write-Host "[fail] Docker daemon unreachable: $($_.Exception.Message)"
    $ok = $false
}

if (-not $ok) {
    exit 1
}
