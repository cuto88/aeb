param(
  [string]$RepoRoot = "",
  [int]$MaxAudits = 3
)

$ErrorActionPreference = "Stop"

function Write-JsonResult {
  param($Data)
  $json = $Data | ConvertTo-Json -Depth 6 -Compress
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

function Get-RelativeRepoPath {
  param(
    [string]$RepoRoot,
    [string]$FullPath
  )

  $repoUri = [System.Uri](([System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\')) + '\')
  $fileUri = [System.Uri]([System.IO.Path]::GetFullPath($FullPath))
  $relative = $repoUri.MakeRelativeUri($fileUri).ToString()
  return [System.Uri]::UnescapeDataString($relative).Replace('/', '\')
}

function Get-Excerpt {
  param(
    [string]$Path,
    [int]$MaxChars = 1200
  )

  $raw = [System.IO.File]::ReadAllText($Path)
  if ($raw.Length -le $MaxChars) {
    return [string]$raw
  }

  return [string]($raw.Substring(0, $MaxChars).TrimEnd() + " ...")
}

function Get-GitSummary {
  param([string]$RepoRoot)

  $branch = (& git -C $RepoRoot branch --show-current).Trim()
  $statusLines = @(& git -C $RepoRoot status --porcelain)
  $commitLines = @(& git -C $RepoRoot log -n 3 --date=iso-strict --pretty=format:"%H`t%ad`t%an`t%s")

  $commits = foreach ($line in $commitLines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line -split "`t", 4
    [ordered]@{
      sha = $parts[0]
      date = if ($parts.Count -ge 2) { $parts[1] } else { "" }
      author = if ($parts.Count -ge 3) { $parts[2] } else { "" }
      subject = if ($parts.Count -ge 4) { $parts[3] } else { "" }
    }
  }

  $modifiedFiles = foreach ($line in $statusLines) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) { continue }
    [ordered]@{
      status = $line.Substring(0, 2).Trim()
      path = $line.Substring(3).Trim()
    }
  }

  [ordered]@{
    name = "aeb"
    path = $RepoRoot
    branch = $branch
    dirty = [bool]($statusLines.Count -gt 0)
    modified_files = @($modifiedFiles)
    latest_commits = @($commits)
  }
}

function Get-AuditSummaries {
  param(
    [string]$RepoRoot,
    [int]$MaxCount
  )

  $auditsRoot = Join-Path $RepoRoot "docs\audits"
  $files = Get-ChildItem -LiteralPath $auditsRoot -Filter "CURRENT_*.md" -File -ErrorAction Stop |
    Where-Object { $_.Name -ne "CURRENT_SUPERVISOR_STATUS.md" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $MaxCount

  @(
    foreach ($file in $files) {
      [ordered]@{
        path = (Get-RelativeRepoPath -RepoRoot $RepoRoot -FullPath $file.FullName)
        last_write_time = $file.LastWriteTime.ToString("s")
        summary = (Get-Excerpt -Path $file.FullName -MaxChars 900)
      }
    }
  )
}

$resolvedRepoRoot = Resolve-AebRepoRoot -Candidate $RepoRoot

$contextPath = Join-Path $resolvedRepoRoot "AI\CONTEXT.md"
$rulesPath = Join-Path $resolvedRepoRoot "AI\RULES.md"
$tasksPath = Join-Path $resolvedRepoRoot "AI\TASKS.md"

foreach ($requiredFile in @($contextPath, $rulesPath, $tasksPath)) {
  if (-not (Test-Path -LiteralPath $requiredFile)) {
    throw "Required supervisor file not found: $requiredFile"
  }
}

$payload = [ordered]@{
  ok = $true
  repo = (Get-GitSummary -RepoRoot $resolvedRepoRoot)
  canonical_files = [ordered]@{
    context_md = (Get-Excerpt -Path $contextPath -MaxChars 1200)
    rules_md = (Get-Excerpt -Path $rulesPath -MaxChars 1200)
    tasks_md = (Get-Excerpt -Path $tasksPath -MaxChars 1200)
  }
  audits = [ordered]@{
    latest_files = (Get-AuditSummaries -RepoRoot $resolvedRepoRoot -MaxCount $MaxAudits)
  }
  timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

Write-JsonResult -Data $payload
