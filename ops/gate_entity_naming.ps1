$ErrorActionPreference = 'Stop'

function Get-CmNamingFiles {
  $files = @()
  if (-not (Test-Path -Path 'packages')) {
    return $files
  }

  $files += Get-ChildItem -Path 'packages' -File -Filter 'cm_*.yaml' -ErrorAction SilentlyContinue |
    ForEach-Object { $_.FullName }
  $files += Get-ChildItem -Path 'packages' -Directory -Filter 'cm_*' -ErrorAction SilentlyContinue |
    ForEach-Object {
      Get-ChildItem -Path $_.FullName -Recurse -File -Include *.yaml, *.yml -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName }
    }

  return $files | Sort-Object -Unique
}

$cmFiles = Get-CmNamingFiles
if ($cmFiles.Count -eq 0) {
  Write-Error 'No cm_* package files found for naming gate.'
  exit 1
}

# Gate 1: canonical cm_* package entity names must keep CM prefix
$invalidNameMatches = foreach ($file in $cmFiles) {
  $content = Get-Content -Path $file -Raw -Encoding UTF8
  [regex]::Matches($content, '(?im)^\s*-\s+name:\s+"?([^"\r\n]+)"?') |
    ForEach-Object {
      $name = $_.Groups[1].Value.Trim()
      if ($name -notmatch '^CM\s') {
        [PSCustomObject]@{
          File = $file
          Name = $name
        }
      }
    }
}
if ($invalidNameMatches.Count -gt 0) {
  Write-Error 'Naming gate failed: cm_* package names without CM prefix.'
  $invalidNameMatches | Sort-Object File, Name | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.Name)
  }
  exit 2
}

# Gate 1b: canonical cm_* package unique_id values must keep cm_ prefix
$invalidUniqueIds = foreach ($file in $cmFiles) {
  $content = Get-Content -Path $file -Raw -Encoding UTF8
  [regex]::Matches($content, '(?im)^\s*unique_id:\s*([a-z0-9_]+)') |
    ForEach-Object {
      $uniqueId = $_.Groups[1].Value.Trim()
      if ($uniqueId -notmatch '^cm_') {
        [PSCustomObject]@{
          File = $file
          UniqueId = $uniqueId
        }
      }
    }
}
if ($invalidUniqueIds.Count -gt 0) {
  Write-Error 'Naming gate failed: cm_* package unique_id without cm_ prefix.'
  $invalidUniqueIds | Sort-Object File, UniqueId | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.File, $_.UniqueId)
  }
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
