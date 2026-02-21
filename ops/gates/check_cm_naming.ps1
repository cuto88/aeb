$ErrorActionPreference = 'Stop'

function Get-CmPackageFiles {
  $files = @()
  if (-not (Test-Path -Path 'packages')) {
    return $files
  }

  $files += Get-ChildItem -Path 'packages' -File -Filter 'cm_*.yaml' -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  $files += Get-ChildItem -Path 'packages' -Directory -Filter 'cm_*' -ErrorAction SilentlyContinue |
    ForEach-Object {
      Get-ChildItem -Path $_.FullName -Recurse -File -Include *.yaml, *.yml -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    }

  return $files | Sort-Object -Unique
}

$files = Get-CmPackageFiles
if ($files.Count -eq 0) {
  Write-Host 'No cm_* package files found. Skipping cm naming gate.'
  exit 0
}

$ruleAViolations = @()
$ruleBViolations = @()

foreach ($file in $files) {
  $content = Get-Content -Path $file -Raw -Encoding UTF8
  $lines = $content -split "`n"

  $invalidUniqueIds = [regex]::Matches($content, '(?im)^\s*unique_id:\s*([a-z0-9_]+)') |
    ForEach-Object { $_.Groups[1].Value.Trim() } |
    Where-Object { $_ -notmatch '^cm_' }
  foreach ($uniqueId in $invalidUniqueIds) {
    $ruleAViolations += [PSCustomObject]@{
      File = $file
      UniqueId = $uniqueId
    }
  }

  $blockHasCmName = $false
  $blockUniqueId = $null
  $blockStartLine = 1

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^\s*-\s+') {
      if ($blockHasCmName -and (-not $blockUniqueId -or $blockUniqueId -notmatch '^cm_')) {
        $ruleBViolations += [PSCustomObject]@{
          File = $file
          Line = $blockStartLine
          UniqueId = $blockUniqueId
        }
      }
      $blockHasCmName = $false
      $blockUniqueId = $null
      $blockStartLine = $i + 1
    }

    if ($line -match '^\s*(name|entity_id|id):\s*"?cm_[^"\s]*"?') {
      $blockHasCmName = $true
    }

    if ($line -match '^\s*unique_id:\s*([a-z0-9_]+)') {
      $blockUniqueId = $Matches[1].Trim()
    }
  }

  if ($blockHasCmName -and (-not $blockUniqueId -or $blockUniqueId -notmatch '^cm_')) {
    $ruleBViolations += [PSCustomObject]@{
      File = $file
      Line = $blockStartLine
      UniqueId = $blockUniqueId
    }
  }
}

if ($ruleAViolations.Count -gt 0 -or $ruleBViolations.Count -gt 0) {
  Write-Host 'CM naming gate failed.'

  if ($ruleAViolations.Count -gt 0) {
    Write-Host 'Violations: unique_id without cm_ prefix in cm_* packages:'
    $ruleAViolations | Sort-Object File, UniqueId | ForEach-Object {
      Write-Host ("- {0}: unique_id={1}" -f $_.File, $_.UniqueId)
    }
  }

  if ($ruleBViolations.Count -gt 0) {
    Write-Host 'Violations: cm_ name/entity_id without cm_ unique_id in same block:'
    $ruleBViolations | Sort-Object File, Line | ForEach-Object {
      $uniqueIdLabel = if ($_.UniqueId) { $_.UniqueId } else { 'missing' }
      Write-Host ("- {0}: line {1} (unique_id={2})" -f $_.File, $_.Line, $uniqueIdLabel)
    }
  }

  exit 1
}

Write-Host 'CM naming gate passed.'
exit 0
