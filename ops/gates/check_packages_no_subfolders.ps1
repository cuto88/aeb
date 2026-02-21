param(
  [string]$RepoRoot = (Resolve-Path "."),
  [switch]$WarningOnly = $false
)

Write-Host "Gate: check_packages_no_subfolders"

$packagesPath = Join-Path $RepoRoot "packages"
if (-not (Test-Path -LiteralPath $packagesPath)) {
  Write-Host "OK: packages/ not found, skipping."
  exit 0
}

$allowed = @("climateops")
$dirs = Get-ChildItem -Path $packagesPath -Directory | Where-Object { $allowed -notcontains $_.Name }

if ($dirs.Count -gt 0) {
  $names = ($dirs | ForEach-Object { "packages/$($_.Name)" }) -join ", "
  $msg = "Nested folders under packages/ are not allowed: $names"

  if ($WarningOnly) {
    Write-Host "WARNING: $msg" -ForegroundColor Yellow
    exit 0
  }

  Write-Host "FAIL: $msg" -ForegroundColor Red
  exit 1
}

Write-Host "OK: No disallowed subfolders found under packages/."
exit 0
