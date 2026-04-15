param(
  [Parameter(Mandatory = $true)]
  [string]$ReportMarkdown,
  [string]$RepoRoot = ""
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
$targetPath = Join-Path $resolvedRepoRoot "docs\audits\CURRENT_SUPERVISOR_STATUS.md"
Write-Utf8NoBomFile -Path $targetPath -Content $ReportMarkdown

Write-JsonResult -Data ([ordered]@{
  ok = $true
  written = $true
  path = $targetPath
  bytes = (New-Utf8NoBomEncoding).GetByteCount($ReportMarkdown)
})
