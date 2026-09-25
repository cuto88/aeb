$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..\ha_config_check.ps1'
$source = Get-Content -LiteralPath $scriptPath -Raw

if ($source -notmatch 'TimeoutSec\s*=\s*300') { throw 'Default timeout must be at least 300 seconds.' }
if ($source -notmatch 'StandardOutput|RedirectStandardOutput') { throw 'stdout capture missing.' }
if ($source -notmatch 'StandardError|RedirectStandardError') { throw 'stderr capture missing.' }
if ($source -notmatch 'EvidencePath') { throw 'EvidencePath parameter missing.' }
if ($source -notmatch 'WriteAllText') { throw 'Atomic evidence write missing.' }
if ($source -notmatch 'Move-Item') { throw 'Atomic evidence rename missing.' }
if ($source -notmatch 'hostname && whoami') { throw 'SSH preflight missing.' }
if ($source -notmatch 'CONFIG_CHECK_TIMEOUT|CONFIG_CHECK_FAIL|CONFIG_CHECK_PASS|SSH_PREFLIGHT_FAIL') { throw 'Result classification missing.' }
if ($source -match '__M63_REMOTE_EXIT__|printf|StdOut\s+-match.*PASS|PASS.*StdOut\s+-match') { throw 'Legacy marker or fragile PASS-text gate found.' }
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $scriptPath), [ref]$null, [ref]$null)
Write-Output 'ha_config_check static tests: PASS'
