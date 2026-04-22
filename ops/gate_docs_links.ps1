$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    $root = $null
    try {
        $root = (& git rev-parse --show-toplevel 2>$null)
    } catch {
        $root = $null
    }
    if ($root) {
        return $root.Trim()
    }
    $fallback = Split-Path -Parent $PSScriptRoot
    if ((Test-Path -LiteralPath (Join-Path $fallback 'docs')) -and (Test-Path -LiteralPath (Join-Path $fallback 'ops'))) {
        return $fallback
    }
    Write-Error 'Unable to resolve repo root.'
    exit 1
}

function Get-MarkdownFiles {
    param([string]$RepoRoot)

    $files = @()
    $docsDir = Join-Path $RepoRoot 'docs'
    if (Test-Path -LiteralPath $docsDir) {
        $files += Get-ChildItem -Path $docsDir -Recurse -Filter '*.md' -File
    }

    $aiDir = Join-Path $RepoRoot 'AI'
    if (Test-Path -LiteralPath $aiDir) {
        $files += Get-ChildItem -Path $aiDir -Recurse -Filter '*.md' -File
    }

    $files += Get-ChildItem -Path $RepoRoot -Filter 'README*.md' -File

    return $files | Sort-Object -Property FullName -Unique
}

function Get-LinkTargets {
    param([string]$Content)

    $targets = @()
    $linkMatches = [regex]::Matches($Content, '\]\(([^)]+)\)')
    foreach ($match in $linkMatches) {
        $raw = $match.Groups[1].Value.Trim()
        if (-not $raw) {
            continue
        }

        if ($raw.StartsWith('<') -and $raw.EndsWith('>')) {
            $raw = $raw.Substring(1, $raw.Length - 2)
        } else {
            if ($raw -match '^\s*([^\s]+)') {
                $raw = $Matches[1]
            }
        }

        $targets += $raw
    }

    return $targets
}

function Remove-CodeFences {
    param([string]$Content)

    return [regex]::Replace($Content, '(?s)```.*?```', '')
}

function Resolve-LinkPath {
    param(
        [string]$BaseDir,
        [string]$Target
    )

    $trimmed = $Target
    if ($trimmed -match '#') {
        $trimmed = $trimmed.Split('#')[0]
    }

    $trimmed = [System.Uri]::UnescapeDataString($trimmed)
    if ($trimmed -match '^[a-zA-Z][a-zA-Z0-9+\-.]*:') {
        if ($trimmed -match '^[a-zA-Z]:[\\/]' -or $trimmed -match '^\\\\') {
            return [System.IO.Path]::GetFullPath($trimmed)
        }
        return $null
    }
    $trimmed = $trimmed -replace '/', [System.IO.Path]::DirectorySeparatorChar

    if (-not $trimmed) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($trimmed)) {
        return [System.IO.Path]::GetFullPath($trimmed)
    }

    $combined = Join-Path $BaseDir $trimmed
    return [System.IO.Path]::GetFullPath($combined)
}

$repoRoot = Get-RepoRoot
$markdownFiles = Get-MarkdownFiles -RepoRoot $repoRoot

$legacyPaths = @(
    'docs/logic/1_vent/',
    'docs/logic/2_vmc/',
    'docs/logic/3_heating/',
    'docs/logic/4_ac/',
    'docs/logic/5_energy_pm/',
    'docs/logic/6_surplus/',
    'docs/logic/archive/logica-redirects/'
)

$brokenLinks = New-Object System.Collections.Generic.List[string]
$legacyMatches = New-Object System.Collections.Generic.List[string]
$missingRiferimenti = New-Object System.Collections.Generic.List[string]

foreach ($file in $markdownFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $contentLower = $content.ToLowerInvariant()
    $contentWithoutCode = Remove-CodeFences -Content $content

    foreach ($legacy in $legacyPaths) {
        if ($contentLower.Contains($legacy.ToLowerInvariant())) {
            $relative = $file.FullName.Substring($repoRoot.Length + 1)
            $legacyMatches.Add("${relative}: ${legacy}")
        }
    }

    $targets = Get-LinkTargets -Content $contentWithoutCode
    foreach ($target in $targets) {
        if ($target -match '^(https?:|mailto:)') {
            continue
        }
        if ($target.StartsWith('#')) {
            continue
        }
        if ($target -match '^[a-zA-Z]:[\\/]') {
            continue
        }

        $targetForPolicy = $target -replace '\\', '/'
        if ($targetForPolicy -match '(^|/)(docs/)?runtime_evidence/') {
            continue
        }

        $resolved = Resolve-LinkPath -BaseDir $file.DirectoryName -Target $target
        if (-not $resolved) {
            continue
        }

        if (-not (Test-Path -LiteralPath $resolved)) {
            $relative = $file.FullName.Substring($repoRoot.Length + 1)
            $brokenLinks.Add("${relative}: ${target}")
            continue
        }

        $item = Get-Item -LiteralPath $resolved
        if ($item.PSIsContainer) {
            $readme = Join-Path $resolved 'README.md'
            if (-not (Test-Path -LiteralPath $readme)) {
                $relative = $file.FullName.Substring($repoRoot.Length + 1)
                $brokenLinks.Add("${relative}: ${target}")
            }
        }
    }
}

$logicRoot = Join-Path $repoRoot 'docs/logic'
if (Test-Path -LiteralPath $logicRoot) {
    $excludedModules = @('core', 'archive', '_backup', 'regole', 'howto')
    $moduleDirs = Get-ChildItem -Path $logicRoot -Directory | Where-Object { $excludedModules -notcontains $_.Name }
    foreach ($module in $moduleDirs) {
        $readme = Join-Path $module.FullName 'README.md'
        if (-not (Test-Path -LiteralPath $readme)) {
            continue
        }

        $lines = Get-Content -LiteralPath $readme
        $sectionIndex = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*##\s+Riferimenti\b') {
                $sectionIndex = $i
                break
            }
        }

        $relative = $readme.Substring($repoRoot.Length + 1)
        if ($sectionIndex -lt 0) {
            $missingRiferimenti.Add("${relative}: missing section")
            continue
        }

        $sectionLines = @()
        for ($j = $sectionIndex + 1; $j -lt $lines.Count; $j++) {
            if ($lines[$j] -match '^\s*##\s+') {
                break
            }
            $sectionLines += $lines[$j]
        }

        $sectionText = $sectionLines -join "`n"
        $requiredRefs = @(
            'docs/logic/core/regole_core_logiche.md',
            'docs/logic/core/README_sensori_clima.md',
            'docs/logic/core/regole_plancia.md',
            'README_ClimaSystem.md'
        )

        $missing = @()
        foreach ($ref in $requiredRefs) {
            if (-not $sectionText.Contains($ref)) {
                $missing += $ref
            }
        }

        if ($missing.Count -gt 0) {
            $missingList = $missing -join ', '
            $missingRiferimenti.Add("${relative}: missing ${missingList}")
        }
    }
}

Write-Host 'BROKEN_LINKS'
if ($brokenLinks.Count -eq 0) {
    Write-Host '  OK'
} else {
    foreach ($entry in $brokenLinks) {
        Write-Host "  - ${entry}"
    }
}

Write-Host 'LEGACY_PATHS'
if ($legacyMatches.Count -eq 0) {
    Write-Host '  OK'
} else {
    foreach ($entry in $legacyMatches) {
        Write-Host "  - ${entry}"
    }
}

Write-Host 'MISSING_RIFERIMENTI'
if ($missingRiferimenti.Count -eq 0) {
    Write-Host '  OK'
} else {
    foreach ($entry in $missingRiferimenti) {
        Write-Host "  - ${entry}"
    }
}

if ($brokenLinks.Count -gt 0 -or $legacyMatches.Count -gt 0 -or $missingRiferimenti.Count -gt 0) {
    exit 1
}

exit 0
