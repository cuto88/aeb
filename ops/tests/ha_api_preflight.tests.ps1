$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..\ha_api_preflight.ps1'
$source = Get-Content -LiteralPath $scriptPath -Raw

if ($source -notmatch '\-Method Get') { throw 'Expected GET-only request.' }
if ($source -match '\-Method\s+(Post|Put|Patch|Delete)') { throw 'Mutating HTTP method found.' }
if ($source -match '(?i)Write-Host.*token|Write-Output.*Authorization') { throw 'Sensitive output path found.' }
if ($source -notmatch 'API_CREDENTIAL_PROVISIONING_REQUIRED') { throw 'Missing credential provisioning result.' }
if ($source -notmatch 'API_REACHABLE=') { throw 'Missing reachability result.' }
if ($source -notmatch 'API_AUTHENTICATED=') { throw 'Missing authentication result.' }
[void][System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path $scriptPath),
  [ref]$null,
  [ref]$null
)
Write-Output 'ha_api_preflight static tests: PASS'
