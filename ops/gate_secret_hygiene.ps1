$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  $root = (& git rev-parse --show-toplevel 2>$null)
  if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
  return (Split-Path -Parent $PSScriptRoot)
}

$repoRoot = Get-RepoRoot
Set-Location $repoRoot

$tracked = @(git ls-files)
if ($LASTEXITCODE -ne 0) { throw 'Unable to enumerate tracked files.' }

$forbiddenPathPattern = '(^|[\\/])\.env($|\.)|(^|[\\/])secrets\.yaml$|(^|[\\/])\.storage([\\/]|$)|(^|[\\/]).*\.(pem|key|p12|pfx|ppk)$|(^|[\\/])id_(rsa|ed25519|ecdsa)(\.|$)'
$forbidden = @($tracked | Where-Object { $_ -match $forbiddenPathPattern })
if ($forbidden.Count -gt 0) {
  $forbidden | ForEach-Object { Write-Error "Tracked sensitive path: $_" }
  exit 1
}

$requiredFiles = @(
  'docs/security/dev-machine.env.example',
  'docs/security/SECRET_HYGIENE.md'
)
foreach ($path in $requiredFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $path))) {
    Write-Error "Missing required security contract file: $path"
    exit 1
  }
}

$requiredEnvNames = @(
  'HA_URL', 'HA_TOKEN', 'HA_SSH_HOST_LAN', 'HA_SSH_KEY_PATH',
  'HA_SSH_KNOWN_HOSTS', 'HA_REMOTE_CONTAINER', 'HA_REMOTE_PATH'
)
$templateNames = @(Get-Content (Join-Path $repoRoot 'docs/security/dev-machine.env.example') |
  ForEach-Object { if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=') { $Matches[1] } })
foreach ($name in $requiredEnvNames) {
  if ($name -notin $templateNames) {
    Write-Error "Missing environment contract name in template: $name"
    exit 1
  }
}

$highConfidence = [ordered]@{
  'private-key-header' = 'BEGIN (OPENSSH|RSA|EC|DSA|PGP) PRIVATE KEY'
  'telegram-token-shape' = '\b\d{8,12}:[A-Za-z0-9_-]{30,}\b'
  'bearer-literal' = '(?i)Bearer\s+[A-Za-z0-9._~+/-]{20,}'
  'github-token-shape' = '\bgh[pousr]_[A-Za-z0-9_]{20,}\b'
  'aws-access-key-shape' = '\bAKIA[0-9A-Z]{16}\b'
}

$skipPathPattern = '(^|[\\/])(custom_components|www)([\\/])|\.map$'
$findings = @()
foreach ($path in $tracked) {
  if ($path -match $skipPathPattern) { continue }
  $fullPath = Join-Path $repoRoot $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { continue }
  $lineNumber = 0
  foreach ($line in Get-Content -LiteralPath $fullPath) {
    $lineNumber++
    foreach ($finding in $highConfidence.GetEnumerator()) {
      if ($line -match $finding.Value) {
        $findings += "${path}:${lineNumber}:$($finding.Key)"
      }
    }
  }
}

if ($findings.Count -gt 0) {
  $findings | Sort-Object -Unique | ForEach-Object { Write-Error "High-confidence secret signature: $_" }
  exit 1
}

Write-Host "SECRET HYGIENE PASS: tracked_paths=$($tracked.Count); findings=0"
exit 0
