param(
    # Il legacy non e` una dashboard operativa registrata: resta un riferimento
    # storico per impedire regressioni dei quattro indicatori VMC nel confronto.
    [string]$Dashboard1 = 'lovelace\_archive\legacy_dashboards\02_air_loop_legacy.yaml',
    [string]$Dashboard2 = 'lovelace\02_air_loop.yaml'
)

$indicators = @(
    'sensor.vmc_freecooling_status',
    'sensor.clima_open_windows_recommended',
    'sensor.delta_t_in_out',
    'sensor.delta_ah_in_out'
)

function Test-VmcDashboard {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string[]]$Indicators
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Error "Dashboard file not found: $Path"
        exit 2
    }

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $missing = @()

    foreach ($indicator in $Indicators) {
        if ($content -notlike "*$indicator*") {
            $missing += $indicator
        }
    }

    if ($missing.Count -eq 0) {
        Write-Host "PASS $Path"
    } else {
        Write-Host "FAIL $Path (missing: $($missing -join ', '))"
    }

    return $missing
}

$dashboards = @($Dashboard1, $Dashboard2)
$anyMissing = $false

foreach ($dashboard in $dashboards) {
    $missing = Test-VmcDashboard -Path $dashboard -Indicators $indicators
    if ($missing.Count -gt 0) {
        $anyMissing = $true
    }
}

if ($anyMissing) {
    exit 3
}

exit 0
