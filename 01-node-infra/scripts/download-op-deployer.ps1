$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-ProjectRoot
$toolsDir = Join-Path $root '.tools'
Ensure-Directory $toolsDir

$setupVersion = '0.6.0-rc.2'
$setupArchive = "op-deployer-$setupVersion-linux-amd64.tar.gz"
$setupUrl = "https://github.com/ethereum-optimism/optimism/releases/download/op-deployer%2Fv$setupVersion/$setupArchive"
$setupArchivePath = Join-Path $toolsDir $setupArchive
$setupExtractDir = Join-Path $toolsDir "op-deployer-$setupVersion-linux"
$setupBinary = Join-Path $setupExtractDir "op-deployer-$setupVersion-linux-amd64\op-deployer"

if (-not (Test-Path $setupBinary)) {
    Write-Host "Downloading $setupArchive..."
    Invoke-WebRequest -Uri $setupUrl -OutFile $setupArchivePath

    if (Test-Path $setupExtractDir) {
        Remove-Item -LiteralPath $setupExtractDir -Recurse -Force
    }
    Ensure-Directory $setupExtractDir
    tar -xzf $setupArchivePath -C $setupExtractDir
} else {
    Write-Host "Setup op-deployer already exists at $setupBinary"
}

if (-not (Test-Path $setupBinary)) {
    throw "Could not install setup op-deployer at $setupBinary"
}

$releaseApi = 'https://api.github.com/repos/ethereum-optimism/optimism/releases'
$assetSuffix = '-windows-amd64.zip'

Write-Host 'Fetching latest Optimism releases for optional Windows binary...'
try {
    $releases = Invoke-RestMethod -Uri $releaseApi -Headers @{ 'User-Agent' = 'codex-op-stack-setup' }
    $release = $releases | Where-Object {
        $_.tag_name -like 'op-deployer/*'
    } | Select-Object -First 1

    if (-not $release) {
        throw 'Could not find an op-deployer release'
    }

    $asset = $release.assets | Where-Object { $_.name -like "*$assetSuffix" } | Select-Object -First 1
    if (-not $asset) {
        throw "Could not find a Windows archive ending with $assetSuffix"
    }

    $targetPath = Join-Path $toolsDir 'op-deployer.exe'
    $zipPath = Join-Path $toolsDir $asset.name
    $extractDir = Join-Path $toolsDir 'op-deployer-extract'

    Write-Host "Downloading $($asset.name) from $($release.tag_name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

    if (Test-Path $extractDir) {
        Remove-Item -LiteralPath $extractDir -Recurse -Force
    }
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $binary = Get-ChildItem -LiteralPath $extractDir -Recurse -Filter 'op-deployer.exe' | Select-Object -First 1
    if (-not $binary) {
        throw 'Could not find op-deployer.exe inside the downloaded archive'
    }

    Copy-Item -LiteralPath $binary.FullName -Destination $targetPath -Force
    Write-Host "Saved optional Windows binary to $targetPath"
} catch {
    Write-Warning "Latest Windows op-deployer download skipped: $($_.Exception.Message)"
}

Write-Host "Ready: $setupBinary"
