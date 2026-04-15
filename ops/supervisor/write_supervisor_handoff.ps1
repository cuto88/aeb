param(
  [Parameter(Mandatory = $true)]
  [string]$HandoffMarkdown,
  [string]$RepoRoot = "",
  [string]$Timestamp = ""
)

$ErrorActionPreference = "Stop"

function New-Utf8NoBomEncoding {
  return [System.Text.UTF8Encoding]::new($false)
}

function Write-JsonResult {
  param([hashtable]$Data)
  $json = $Data | ConvertTo-Json -Depth 6 -Compress
  [Console]::OutputEncoding = New-Utf8NoBomEncoding
  Write-Output $json
}

function Resolve-AebRepoRoot {
  param([string]$Candidate)

  $defaultRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
  $resolved = if ([string]::IsNullOrWhiteSpace($Candidate)) {
    $defaultRoot
  } else {
    (Resolve-Path -LiteralPath $Candidate -ErrorAction Stop).Path
  }

  if ($resolved -ne $defaultRoot) {
    throw "Unsupported repo root: $resolved"
  }

  return $resolved
}

function Get-SafeTimestamp {
  param([string]$Candidate)

  if ([string]::IsNullOrWhiteSpace($Candidate)) {
    return (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
  }

  if ($Candidate -notmatch '^[0-9]{8}T[0-9]{6}Z$') {
    throw "Invalid timestamp format. Expected yyyyMMddTHHmmssZ."
  }

  return $Candidate
}

function Write-Utf8NoBomFile {
  param(
    [string]$Path,
    [string]$Content
  )

  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  [System.IO.File]::WriteAllText($Path, $Content, (New-Utf8NoBomEncoding))
}

$resolvedRepoRoot = Resolve-AebRepoRoot -Candidate $RepoRoot
$safeTimestamp = Get-SafeTimestamp -Candidate $Timestamp
$handoffDir = Join-Path $resolvedRepoRoot "AI\handoffs"
$targetPath = Join-Path $handoffDir ($safeTimestamp + "_supervisor_task.md")
Write-Utf8NoBomFile -Path $targetPath -Content $HandoffMarkdown

Write-JsonResult -Data ([ordered]@{
  ok = $true
  written = $true
  path = $targetPath
  bytes = (New-Utf8NoBomEncoding).GetByteCount($HandoffMarkdown)
})
