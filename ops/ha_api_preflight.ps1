[CmdletBinding()]
param(
  [string]$EnvPath = (Join-Path (Split-Path -Parent $PSScriptRoot) '.env'),
  [string]$Endpoint = '/api/'
)

$ErrorActionPreference = 'Stop'

function Read-DotEnvValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Credential store unavailable: $Path"
  }

  foreach ($line in [IO.File]::ReadLines($Path)) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
      continue
    }
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2 -and $parts[0].Trim() -eq $Name) {
      return $parts[1].Trim().Trim('"').Trim("'")
    }
  }
  return $null
}

if ($Endpoint -notmatch '^/api(?:/|$)' -or $Endpoint -match '[\r\n]') {
  throw 'Only Home Assistant /api/ endpoints are allowed.'
}

if (-not (Test-Path -LiteralPath $EnvPath -PathType Leaf)) {
  Write-Output 'API_REACHABLE=UNKNOWN API_AUTHENTICATED=UNKNOWN RESULT=API_CREDENTIAL_PROVISIONING_REQUIRED'
  exit 3
}

$baseUrl = Read-DotEnvValue -Path $EnvPath -Name 'HA_URL'
$token = Read-DotEnvValue -Path $EnvPath -Name 'HA_TOKEN'
if ([string]::IsNullOrWhiteSpace($baseUrl) -or [string]::IsNullOrWhiteSpace($token)) {
  Write-Output 'API_REACHABLE=UNKNOWN API_AUTHENTICATED=UNKNOWN RESULT=API_CREDENTIAL_PROVISIONING_REQUIRED'
  exit 3
}

$uri = $baseUrl.TrimEnd('/') + $Endpoint
try {
  $response = Invoke-WebRequest -Method Get -Uri $uri `
    -Headers @{ Authorization = ('Bearer ' + $token) } `
    -TimeoutSec 15 -UseBasicParsing -SkipHttpErrorCheck
  $status = [int]$response.StatusCode
  $reachable = if ($status -ge 100 -and $status -lt 600) { 'PASS' } else { 'FAIL' }
  $authenticated = if ($status -ge 200 -and $status -lt 300) { 'PASS' } elseif ($status -in 401, 403) { 'FAIL' } else { 'UNKNOWN' }
  Write-Output "ENDPOINT=$Endpoint STATUS_HTTP=$status API_REACHABLE=$reachable API_AUTHENTICATED=$authenticated RESPONSE=SANITIZED"
  if ($status -lt 200 -or $status -ge 300) { exit 1 }
  exit 0
}
catch {
  Write-Output "ENDPOINT=$Endpoint STATUS_HTTP=UNKNOWN API_REACHABLE=FAIL API_AUTHENTICATED=UNKNOWN RESPONSE=SANITIZED"
  exit 1
}
