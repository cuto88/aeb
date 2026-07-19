# ops/gate_include_tree.ps1
# Validates that all !include* references point to existing paths.
# Non-invasive: just fails fast on missing includes.

param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Fail($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; exit 1 }
function Ok($msg)   { Write-Host "[OK]   $msg" -ForegroundColor Green }

Set-Location (Resolve-Path $Root)

# `!include_dir_named packages` scans YAML below the directory recursively.
# Backup YAML kept below packages can silently override the active package.
$unsafePackageBackups = @(
  Get-ChildItem -Path .\packages -Recurse -Include "*.yaml","*.yml" -File -ErrorAction SilentlyContinue |
    Where-Object {
      $_.FullName -match '[\\/](?:_codex_backups|_backup|backup|backups)(?:[\\/]|$)'
    }
)
if ($unsafePackageBackups.Count -gt 0) {
  $unsafePackageBackups | ForEach-Object { Write-Host " - $($_.FullName)" }
  Fail "Backup YAML found below packages; move it outside the included package tree."
}

# Scan YAML files that can contain includes (exclude backups/runtime)
$excludeDirs = @(
  "\.git\",
  "\_backup_pre_git\",
  "\_ha_runtime_backups\",
  "\backup\",
  "\_backup\",
  "\_quarantine\"
)

$files = @()
$files += Get-ChildItem -Path . -Filter "configuration.yaml" -File -ErrorAction SilentlyContinue

$files += Get-ChildItem -Path . -Recurse -Include "*.yaml","*.yml" -File -ErrorAction SilentlyContinue |
  Where-Object {
    $p = $_.FullName
    foreach ($ex in $excludeDirs) { if ($p -match [regex]::Escape($ex)) { return $false } }
    return $true
  }


if (-not $files -or $files.Count -eq 0) { Fail "No YAML files found to scan." }

$includePatterns = @(
  "!include_dir_named",
  "!include_dir_merge_named",
  "!include_dir_list",
  "!include_dir_merge_list",
  "!include"
)

$missing = New-Object System.Collections.Generic.List[string]
$checked = 0

foreach ($f in $files) {
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction Stop
  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    foreach ($p in $includePatterns) {
      if ($line -match [regex]::Escape($p)) {
        # Extract path after the include directive
        # Examples:
        #   something: !include foo.yaml
        #   <<: !include_dir_named packages
        $m = [regex]::Match($line, "$([regex]::Escape($p))\s+([^\s#]+)")
        if ($m.Success) {
          $path = $m.Groups[1].Value.Trim()

          # Remove quotes if present
          $path = $path.Trim("'`"")

          # Resolve relative to file directory
          $base = Split-Path -Parent $f.FullName
          $full = Join-Path $base $path

          $checked++
          if (-not (Test-Path -LiteralPath $full)) {
            $missing.Add(("{0}:{1} -> {2} (resolved: {3})" -f $f.FullName, ($i+1), $path, $full))
          }
        }
      }
    }
  }
}

if ($missing.Count -gt 0) {
  Write-Host ""
  Write-Host "Missing include targets:" -ForegroundColor Yellow
  $missing | ForEach-Object { Write-Host " - $_" }
  Write-Host ""
  Fail ("Include-tree check failed: {0} missing path(s) (checked {1} include(s))." -f $missing.Count, $checked)
}

Ok ("Include-tree check passed (checked {0} include(s))." -f $checked)
exit 0

