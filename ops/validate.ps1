[CmdletBinding()]
param(
    [switch]$HaCheck
)

$ErrorActionPreference = 'Stop'

function Get-PowerShellHost {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        return 'pwsh'
    }
    if (Get-Command powershell -ErrorAction SilentlyContinue) {
        return 'powershell'
    }
    throw "No PowerShell host found (pwsh/powershell)."
}

function Invoke-Phase {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Write-Host ''
    Write-Host ("==> {0}" -f $Name)
    & $Action
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 1
    }
    return $code
}

function Get-ExitCode {
    param($Value)

    $candidate = $Value
    if ($Value -is [System.Array]) {
        $candidate = $null
        for ($i = $Value.Length - 1; $i -ge 0; $i--) {
            $item = $Value[$i]
            if ($null -eq $item) {
                continue
            }

            $parsed = 0
            if ([int]::TryParse([string]$item, [ref]$parsed)) {
                $candidate = $parsed
                break
            }
        }

        if ($null -eq $candidate) {
            $candidate = $LASTEXITCODE
        }
    }

    try {
        return [int]$candidate
    }
    catch {
        if ($null -ne $LASTEXITCODE) {
            try {
                return [int]$LASTEXITCODE
            }
            catch {
            }
        }
        return 1
    }
}

$results = [ordered]@{
    gates = 'pending'
    ha    = if ($HaCheck) { 'pending' } else { 'skipped' }
}

function Print-Summary {
    param([int]$ExitCode)

    Write-Host ''
    Write-Host '========================================='
    Write-Host ' Validation Summary'
    Write-Host '========================================='
    Write-Host ("gates_run.ps1 : {0}" -f $results.gates)
    Write-Host ("ha core check : {0}" -f $results.ha)
    Write-Host ("exit code     : {0}" -f $ExitCode)
}

$gatesScript = Join-Path $PSScriptRoot 'gates_run.ps1'
if (-not (Test-Path $gatesScript)) {
    Write-Host ("Missing script: {0}" -f $gatesScript)
    Print-Summary -ExitCode 1
    exit 1
}

$gatesCode = Get-ExitCode (Invoke-Phase -Name 'Running repo gates (ops/gates_run.ps1)' -Action {
    $ps = Get-PowerShellHost
    & $ps -NoProfile -ExecutionPolicy Bypass -File $gatesScript
})
if ($gatesCode -ne 0) {
    $results.gates = "failed (exit=$gatesCode)"
    Print-Summary -ExitCode $gatesCode
    exit $gatesCode
}
$results.gates = 'passed'

if ($HaCheck) {
    $haCode = Get-ExitCode (Invoke-Phase -Name 'Running Home Assistant check (ha core check)' -Action {
        if (-not (Get-Command ha -ErrorAction SilentlyContinue)) {
            Write-Host "ha CLI not found. Install/use HA CLI or run without -HaCheck."
            $global:LASTEXITCODE = 127
            return
        }
        & ha core check
    })

    if ($haCode -ne 0) {
        $results.ha = "failed (exit=$haCode)"
        Print-Summary -ExitCode $haCode
        exit $haCode
    }
    $results.ha = 'passed'
}

Print-Summary -ExitCode 0
exit 0
