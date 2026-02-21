$ErrorActionPreference = 'Stop'

$bridgePath = 'packages/cm_naming_bridge.yaml'
if (-not (Test-Path -Path $bridgePath)) {
  Write-Error "Naming bridge file not found: $bridgePath"
  exit 1
}

$bridgeContent = Get-Content -Path $bridgePath -Raw -Encoding UTF8

# Gate 1: cm_ prefix required for Step 4 bridge names/unique_id
$invalidNameMatches = [regex]::Matches($bridgeContent, '(?im)^\s*-\s+name:\s+"?([^"\r\n]+)"?') |
  ForEach-Object { $_.Groups[1].Value.Trim() } |
  Where-Object { $_ -notmatch '^CM\s' }
if ($invalidNameMatches.Count -gt 0) {
  Write-Error ('Naming gate failed: bridge names without CM prefix: {0}' -f (($invalidNameMatches | Sort-Object -Unique) -join ', '))
  exit 2
}

$invalidUniqueIds = [regex]::Matches($bridgeContent, '(?im)^\s*unique_id:\s*([a-z0-9_]+)') |
  ForEach-Object { $_.Groups[1].Value.Trim() } |
  Where-Object { $_ -notmatch '^cm_' }
if ($invalidUniqueIds.Count -gt 0) {
  Write-Error ('Naming gate failed: Step 4 unique_id without cm_ prefix: {0}' -f (($invalidUniqueIds | Sort-Object -Unique) -join ', '))
  exit 3
}

# Gate 2: no duplicate unique_id across tracked YAML
$files = @()
if (Test-Path -Path 'packages') {
  $files += Get-ChildItem -Path 'packages' -Recurse -File -Include *.yaml, *.yml | ForEach-Object { $_.FullName }
}
if (Test-Path -Path 'lovelace') {
  $files += Get-ChildItem -Path 'lovelace' -Recurse -File -Include *.yaml, *.yml | ForEach-Object { $_.FullName }
}
if ($files.Count -eq 0) {
  Write-Error 'No YAML files found in packages/ or lovelace/ for unique_id check.'
  exit 4
}

$allUniqueIds = @()
foreach ($file in $files) {
  $content = Get-Content -Path $file -Raw -Encoding UTF8
  $matches = [regex]::Matches($content, '(?im)^\s*unique_id:\s*([a-z0-9_]+)')
  foreach ($m in $matches) {
    $allUniqueIds += [PSCustomObject]@{
      UniqueId = $m.Groups[1].Value.Trim().ToLowerInvariant()
      File = $file
    }
  }
}

$dupes = $allUniqueIds |
  Group-Object -Property UniqueId |
  Where-Object { $_.Count -gt 1 }

if ($dupes.Count -gt 0) {
  Write-Error 'Naming gate failed: duplicate unique_id detected.'
  $dupes | ForEach-Object {
    $filesList = ($_.Group | Select-Object -ExpandProperty File | Sort-Object -Unique) -join ', '
    Write-Host ("- {0} -> {1}" -f $_.Name, $filesList)
  }
  exit 5
}

Write-Host 'Entity naming gate passed.'
exit 0
