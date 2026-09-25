$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..\ha_config_check.ps1'
$source = Get-Content -LiteralPath $scriptPath -Raw

if ($source -notmatch 'TimeoutSec\s*=\s*300') { throw 'Default timeout must be at least 300 seconds.' }
if ($source -notmatch 'StandardOutput|RedirectStandardOutput') { throw 'stdout capture missing.' }
if ($source -notmatch 'StandardError|RedirectStandardError') { throw 'stderr capture missing.' }
if ($source -notmatch 'RemoteExitCode') { throw 'remote exit-code propagation missing.' }
if ($source -match '(?i)StdOut\s+-match.*PASS|PASS.*StdOut\s+-match') { throw 'Fragile PASS-text gate found.' }
if ($source -notmatch 'CONFIG_CHECK_TIMEOUT|CONFIG_CHECK_FAIL|CONFIG_CHECK_PASS') { throw 'Result classification missing.' }
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $scriptPath), [ref]$null, [ref]$null)
Write-Output 'ha_config_check static tests: PASS'
