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
    throw 'Unable to resolve repo root.'
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

function Get-TrackedYamlFiles {
    param(
        [string]$Root,
        [string]$Pattern
    )

    $tracked = @()
    $output = $null
    $gitOk = $false
    try {
        $output = & git -C $Root ls-files -z -- $Pattern 2>$null
        $gitOk = ($LASTEXITCODE -eq 0)
    } catch {
        $gitOk = $false
    }
    if ($gitOk -and $output) {
        $tracked = $output -split "`0" | Where-Object { $_ -ne '' }
        return $tracked
    }
    $base = if ($Pattern -like 'packages/*') { 'packages' } elseif ($Pattern -like 'lovelace/*') { 'lovelace' } else { '' }
    if (-not $base) { return @() }
    $dir = Join-Path $Root $base
    if (-not (Test-Path -LiteralPath $dir)) { return @() }
    return @(
        Get-ChildItem -Path $dir -File -Include '*.yaml', '*.yml' |
            ForEach-Object { "$base/$($_.Name)" }
    )
}

try {
    $repoRoot = Get-RepoRoot
    $markdownFiles = Get-MarkdownFiles -RepoRoot $repoRoot
    $allMarkdown = ($markdownFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
    $allLower = $allMarkdown.ToLowerInvariant()

    $packageFiles = Get-TrackedYamlFiles -Root $repoRoot -Pattern 'packages/*.yaml'
    $lovelaceFiles = Get-TrackedYamlFiles -Root $repoRoot -Pattern 'lovelace/*.yaml'

    $packageWarnings = @()
    foreach ($file in $packageFiles) {
        if (-not $allLower.Contains($file.ToLowerInvariant())) {
            $packageWarnings += $file
        }
    }

    if ($packageWarnings.Count -eq 0) {
        if ($packageFiles.Count -eq 0) {
            Write-Host '[OK] PACKAGES: no tracked packages'
        } else {
            Write-Host '[OK] PACKAGES: all documented'
        }
    } else {
        foreach ($entry in $packageWarnings) {
            Write-Host "[WARN] UNDOCUMENTED_PACKAGE: ${entry}"
        }
    }

    $lovelaceWarnings = @()
    foreach ($file in $lovelaceFiles) {
        if (-not $allLower.Contains($file.ToLowerInvariant())) {
            $lovelaceWarnings += $file
        }
    }

    if ($lovelaceWarnings.Count -eq 0) {
        if ($lovelaceFiles.Count -eq 0) {
            Write-Host '[OK] LOVELACE: no tracked lovelace dashboards'
        } else {
            Write-Host '[OK] LOVELACE: all documented'
        }
    } else {
        foreach ($entry in $lovelaceWarnings) {
            Write-Host "[WARN] UNDOCUMENTED_LOVELACE: ${entry}"
        }
    }
} catch {
    Write-Host "[WARN] DOCS_WARN_ERROR: $($_.Exception.Message)"
} finally {
    exit 0
}
