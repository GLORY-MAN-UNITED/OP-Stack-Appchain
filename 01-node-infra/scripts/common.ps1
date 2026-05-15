function Get-ProjectRoot {
    Split-Path -Parent $PSScriptRoot
}

function Get-DeployerCacheDir {
    Join-Path (Get-ProjectRoot) '.deployer-cache'
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Read-EnvFile {
    param([string]$Path)

    $map = @{}
    if (-not (Test-Path $Path)) {
        return $map
    }

    foreach ($line in Get-Content $Path) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') {
            continue
        }

        $parts = $line -split '=', 2
        if ($parts.Length -ne 2) {
            continue
        }

        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        if ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Trim('"')
        }
        $map[$key] = $value
    }

    return $map
}

function Get-Setting {
    param(
        [hashtable]$Settings,
        [string]$Name,
        [string]$FallbackName = '',
        [string]$DefaultValue = ''
    )

    if ($Settings.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace($Settings[$Name])) {
        return $Settings[$Name]
    }

    if ($FallbackName -and $Settings.ContainsKey($FallbackName) -and -not [string]::IsNullOrWhiteSpace($Settings[$FallbackName])) {
        return $Settings[$FallbackName]
    }

    return $DefaultValue
}

function Require-Settings {
    param(
        [hashtable]$Settings,
        [string[]]$Names
    )

    $missing = @()
    foreach ($name in $Names) {
        if ([string]::IsNullOrWhiteSpace((Get-Setting $Settings $name))) {
            $missing += $name
        }
    }

    if ($missing.Count -gt 0) {
        throw "Missing required settings: $($missing -join ', ')"
    }
}

function New-HexSecret {
    param([int]$Bytes = 32)

    $buffer = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($buffer)
    } finally {
        $rng.Dispose()
    }
    -join ($buffer | ForEach-Object { $_.ToString('x2') })
}

function Set-OrReplaceTomlValue {
    param(
        [string]$Path,
        [string]$Key,
        [string]$Value,
        [switch]$StringValue,
        [switch]$Optional
    )

    $content = Get-Content $Path -Raw
    $escapedKey = [regex]::Escape($Key)
    $replacementValue = if ($StringValue) { '"' + $Value + '"' } else { $Value }
    $pattern = "(?m)^(\s*$escapedKey\s*=\s*).*$"

    if ($content -notmatch $pattern) {
        if ($Optional) {
            return
        }
        throw "Could not find TOML key '$Key' in $Path"
    }

    $regex = [regex]::new($pattern)
    $updated = $regex.Replace($content, { param($match) $match.Groups[1].Value + $replacementValue }, 1)
    Set-Content -LiteralPath $Path -Value $updated -Encoding UTF8
}

function Normalize-PrivateKey {
    param([string]$PrivateKey)

    $value = $PrivateKey.Trim()
    if ($value.StartsWith('0x')) {
        return $value.Substring(2)
    }

    return $value
}

function Format-ChainIdHex32 {
    param([string]$ChainId)

    $big = [System.Numerics.BigInteger]::Parse($ChainId)
    return '0x' + $big.ToString('x').PadLeft(64, '0')
}

function Remove-TomlKey {
    param(
        [string]$Path,
        [string]$Key
    )

    $content = Get-Content $Path -Raw
    $escapedKey = [regex]::Escape($Key)
    $updated = [regex]::Replace($content, "(?m)^\s*$escapedKey\s*=.*(?:\r?\n)?", '')
    Set-Content -LiteralPath $Path -Value $updated -Encoding UTF8
}

function Write-KeyValueFile {
    param(
        [string]$Path,
        [hashtable]$Values
    )

    $lines = foreach ($key in ($Values.Keys | Sort-Object)) {
        "$key=$($Values[$key])"
    }

    $text = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
    Set-Content -LiteralPath $Path -Value $text -Encoding ASCII
}

function Assert-LastExitCode {
    param([string]$Context)

    if ($LASTEXITCODE -ne 0) {
        throw "$Context failed with exit code $LASTEXITCODE"
    }
}
