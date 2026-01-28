[CmdletBinding()]
param(
  [switch]$CheckEntityMap
)

$ErrorActionPreference = 'Stop'

function Get-FirstNonEmptyLine([string] $path) {
  foreach ($line in Get-Content -Path $path) {
    $trimmed = $line.Trim()
    if ($trimmed -and -not $trimmed.StartsWith('#')) {
      return $trimmed
    }
  }
  return $null
}

function Test-IsAllowedMissing {
  param(
    [string]$EntityId,
    [string[]]$AllowMissingPrefixes
  )
  if (-not $EntityId) {
    return $false
  }
  foreach ($prefix in $AllowMissingPrefixes) {
    if ($EntityId.StartsWith($prefix)) {
      return $true
    }
  }
  return $false
}

$fail = $false

$legacyMiraiPath = 'packages/mirai.yaml'
if (Test-Path -Path $legacyMiraiPath) {
  Write-Warning 'legacy mirai.yaml present'
}

$miraiSplitFiles = @(
  'packages/mirai_core.yaml',
  'packages/mirai_modbus.yaml',
  'packages/mirai_templates.yaml'
)
$missingMiraiFiles = @()
foreach ($miraiFile in $miraiSplitFiles) {
  if (-not (Test-Path -Path $miraiFile)) {
    Write-Warning ("Missing {0}" -f $miraiFile)
    $missingMiraiFiles += $miraiFile
  }
}
if ($missingMiraiFiles.Count -eq 0) {
  Write-Host 'Mirai split files present: OK'
}

$legacyTemplatePath = 'mirai/20_templates.yaml'
if (Test-Path -Path $legacyTemplatePath) {
  Write-Host "Legacy found: $legacyTemplatePath (checking)"
  $templateRoot = Get-FirstNonEmptyLine $legacyTemplatePath
  if ($templateRoot -match '^template\s*:') {
    Write-Warning "Invalid template root in mirai/20_templates.yaml: file must be a list without 'template:'."
  }
} else {
  Write-Verbose "Skipping legacy $legacyTemplatePath (not found)"
}

$legacyAutomationPath = 'mirai/30_automations.yaml'
if (Test-Path -Path $legacyAutomationPath) {
  Write-Host "Legacy found: $legacyAutomationPath (checking)"
  $automationRoot = Get-FirstNonEmptyLine $legacyAutomationPath
  if ($automationRoot -and ($automationRoot -notmatch '^-')) {
    Write-Warning "Invalid automation root in mirai/30_automations.yaml: file must start with a list item '-'."
  }
} else {
  Write-Verbose "Skipping legacy $legacyAutomationPath (not found)"
}

$fail = $false

if ($CheckEntityMap) {
  $scriptRoot = Split-Path -Parent $PSCommandPath
  $AllowMissingPrefixes = @(
    'sensor.climateops_',
    'binary_sensor.climateops_',
    'input_boolean.climateops_',
    'input_number.climateops_',
    'input_datetime.climateops_',
    'input_text.climateops_',
    'switch.climateops_'
  )
  $entityOutput = & (Join-Path $scriptRoot 'gate_entity_map.ps1') -Mode strict_clima 2>&1
  $entityOutput | ForEach-Object { Write-Host $_ }

  $missingLines = @()
  $inMissingSection = $false
  $hasNonMissingErrors = $false
  foreach ($line in $entityOutput) {
    $lineText = $line.ToString()
    if ($lineText -match '^ERROR:' -and $lineText -notmatch 'Missing in map') {
      $hasNonMissingErrors = $true
    }
    if ($lineText -match '--- Missing in map') {
      $inMissingSection = $true
      continue
    }
    if ($inMissingSection) {
      if ($lineText -match '^\s*-\s*') {
        $missingLines += $lineText
        continue
      }
      if ($lineText -notmatch '^\s*$') {
        $inMissingSection = $false
      }
    }
  }

  $missingAllowed = @()
  $missingAllowedLines = @()
  $missingBlocking = @()
  foreach ($line in $missingLines) {
    if ($line -match '^\s*-\s*([a-z_]+\.[a-z0-9_]+)\b') {
      $entityId = $matches[1]
      if (Test-IsAllowedMissing -EntityId $entityId -AllowMissingPrefixes $AllowMissingPrefixes) {
        $missingAllowed += $entityId
        $missingAllowedLines += $line
      } else {
        $missingBlocking += $entityId
      }
    }
  }

  $missingBlockingCount = $missingBlocking.Count
  $missingAllowedCount = $missingAllowed.Count

  if ($missingBlockingCount -gt 0 -or $hasNonMissingErrors) {
    $fail = $true
    Write-Error ("Entity map gate failed: blocking missing entities found ({0})." -f $missingBlockingCount)
  } elseif ($missingAllowedCount -gt 0) {
    Write-Warning ("Missing in map allowed for climateops prefixes: {0}" -f $missingAllowedCount)
    Write-Warning '--- Missing in map allowed (showing up to 50) ---'
    $missingAllowedLines | Select-Object -First 50 | ForEach-Object { Write-Warning $_ }
  }
}
# Ensure legacy/optional checks do not fail the gate
if (-not $CheckEntityMap) {
  $fail = $false
}

if ($fail) {
  exit 1
} else {
  Write-Host 'MIRAI package structure check passed.'
  exit 0
}
