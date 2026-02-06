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

function Invoke-PSFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$Args = @()
    )
    $ps = Get-PowerShellHost
    & $ps -NoProfile -ExecutionPolicy Bypass -File $Path @Args
    $code = $LASTEXITCODE
    return $code
}

function Invoke-Gate {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Args = @()
    )
    Write-Host ''
    $argsDisplay = if ($Args.Count -gt 0) { " $($Args -join ' ')" } else { '' }
    Write-Host ("==> [{0}] {1}{2}" -f $Name, $ScriptPath, $argsDisplay)
    $p = Start-Process -FilePath "powershell" -ArgumentList @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        $ScriptPath
        $Args
    ) -Wait -PassThru -NoNewWindow
    $code = $p.ExitCode
    Write-Host ("[{0}] exit={1}" -f $Name, $code)
    return $code
}

Write-Host '========================================='
Write-Host ' Running Manual Quality Gates'
Write-Host '========================================='

function Get-RepoRoot {
    $root = (& git rev-parse --show-toplevel 2>$null)
    if (-not $root) {
        Write-Error 'Unable to resolve git repo root.'
        exit 1
    }
    return $root.Trim()
}

function Get-TrackedYamlFiles {
    param([string]$Root)
    $tracked = @()
    $output = & git -C $Root ls-files -z -- '*.yaml' '*.yml' 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Unable to enumerate tracked YAML files.'
        exit 1
    }
    if ($output) {
        $tracked = $output -split "`0" | Where-Object { $_ -ne '' }
    }
    return $tracked
}

$repoRoot = Get-RepoRoot
$trackedYamlFiles = Get-TrackedYamlFiles -Root $repoRoot

$gates = @(
    # HYGIENE = formatter/mutating scripts (non-validation).
    @{ Name = '[HYGIENE] ops/hygiene_fix_yaml_encoding.ps1 (mutating formatter)'; Gate = 'HYGIENE'; Script = 'ops/hygiene_fix_yaml_encoding.ps1'; Args = @(); UsePowerShell = $true },
    # GATE = validation/non-mutating checks.
    @{ Name = '[GATE 1] yamllint tracked YAML (validation)'; Command = 'yamllint'; Args = @(); UsePowerShell = $false },
    @{ Name = '[GATE 2] ops/gate_include_tree.ps1'; Gate = 'GATE 2'; Script = 'ops/gate_include_tree.ps1'; Args = @(); UsePowerShell = $true },
    @{ Name = '[GATE 3] ops/gate_ha_structure.ps1 -CheckEntityMap'; Gate = 'GATE 3'; Script = 'ops/gate_ha_structure.ps1'; Args = @('-CheckEntityMap'); UsePowerShell = $true },
    @{ Name = '[GATE 4] VMC dashboards gate'; Gate = 'GATE 4'; Script = 'ops/gate_vmc_dashboards.ps1'; Args = @(); UsePowerShell = $true },
    @{ Name = '[GATE 5] Entity naming gate'; Gate = 'GATE 5'; Script = 'ops/gate_entity_naming.ps1'; Args = @(); UsePowerShell = $true },
    @{ Name = '[GATE 6] DOCS ops/gate_docs_links.ps1'; Gate = 'GATE 6'; Script = 'ops/gate_docs_links.ps1'; Args = @(); UsePowerShell = $true }
)

foreach ($gate in $gates) {
    if ($gate.UsePowerShell) {
        if (Test-Path -Path $gate.Script) {
            $code = Invoke-Gate -Name $gate.Gate -ScriptPath $gate.Script -Args @($gate.Args)
            if ($gate.Script -eq 'ops/gate_docs_links.ps1') {
                if ($code -eq 0) {
                    Write-Host 'DOCS_GATE: OK'
                } else {
                    Write-Host 'DOCS_GATE: FAIL'
                }
            }
        } else {
            Write-Host ''
            Write-Host ("==> Skipping {0} (not found)" -f $gate.Name)
            continue
        }
    } else {
        if (Get-Command $gate.Command -ErrorAction SilentlyContinue) {
            Write-Host ''
            Write-Host ("==> {0}" -f $gate.Name)
            if ($gate.Command -eq 'yamllint') {
                if ($trackedYamlFiles.Count -eq 0) {
                    Write-Host "No tracked YAML files found. Skipping yamllint."
                    $code = 0
                } else {
                    & $gate.Command @($trackedYamlFiles)
                    $code = $LASTEXITCODE
                    if ($code -eq 1) {
                        Write-Host "yamllint returned warnings only; continuing."
                        $code = 0
                    }
                }
            } else {
                & $gate.Command @($gate.Args)
                $code = $LASTEXITCODE
            }
        } else {
            Write-Host ''
            Write-Host ("==> Skipping {0} (not found)" -f $gate.Name)
            continue
        }
    }

    if ($null -eq $code) {
        Write-Host ("Gate failed: {0} (no exit code)" -f $gate.Name)
        exit 1
    }
    if ($code -ne 0) {
        Write-Host ("Gate failed: {0} (exit={1})" -f $gate.Name, $code)
        exit $code
    }
}

Write-Host ''
Write-Host '==> DOCS WARN'
try {
    if (Test-Path -Path 'ops/gate_docs_warn.ps1') {
        $code = Invoke-PSFile 'ops/gate_docs_warn.ps1'
    } else {
        Write-Host 'Skipping DOCS WARN (not found)'
    }
} catch {
    Write-Host ("[WARN] DOCS WARN failed: {0}" -f $_.Exception.Message)
}

Write-Host ''
Write-Host 'ALL GATES PASSED'

# Scrive il marker gates.ok solo in caso di successo completo
$opsStateDir = Join-Path $repoRoot ".ops_state"
New-Item -ItemType Directory -Force -Path $opsStateDir | Out-Null

$head = (git rev-parse HEAD).Trim()
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

$gatesContent = @(
    "HEAD=$head"
    "BRANCH=$branch"
    "TIMESTAMP=$timestamp"
)

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines((Join-Path $opsStateDir "gates.ok"), $gatesContent, $utf8NoBom)

exit 0
