$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..\ha_service_call.ps1'
$source = Get-Content -LiteralPath $scriptPath -Raw

if ($source -notmatch '\$AllowedEndpoint\s*=\s*''/api/services/input_boolean/turn_on''') { throw 'Endpoint allowlist missing.' }
if ($source -notmatch '\$AllowedEntity\s*=\s*''input_boolean\.ehw_shadow_enabled''') { throw 'Entity allowlist missing.' }
if ($source -notmatch '\-Method Post') { throw 'POST path missing.' }
if ($source -notmatch 'ConvertTo-Json -Compress') { throw 'Structured JSON payload missing.' }
if ($source -notmatch 'ContentType\s*=\s*''application/json''') { throw 'Content-Type contract missing.' }
if ($source -match '(?i)retry|automatic.*retry') { throw 'Retry language/code found.' }
if ($source -match '(?i)Write-Host.*token|Write-Output.*Authorization') { throw 'Sensitive output path found.' }
if ($source -notmatch 'StateBefore|StateAfter') { throw 'State verification missing.' }
if ($source -notmatch 'StatusCode -lt 200|StatusCode -ge 300') { throw 'Non-2xx failure check missing.' }
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $scriptPath), [ref]$null, [ref]$null)
Write-Output 'ha_service_call static tests: PASS'
