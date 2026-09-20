param(
  [string]$RepoRoot = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepoRoot).Path

function Fail([string]$Message) {
  Write-Error $Message
  exit 1
}

$raw = & git -C $root ls-files -z 2>$null
if ($LASTEXITCODE -ne 0 -or -not $raw) {
  Fail 'Secret hygiene gate requires a Git working tree with tracked-file metadata.'
}
$tracked = $raw -split "`0" | Where-Object { $_ }

$forbiddenNames = @('secrets.yaml', '.env', 'id_rsa', 'id_ed25519')
$forbiddenExtensions = @('.pem', '.p12', '.pfx')
$badFiles = @()

foreach ($rel in $tracked) {
  $leaf = [System.IO.Path]::GetFileName($rel)
  $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
  if ($forbiddenNames -contains $leaf -or $forbiddenExtensions -contains $ext) {
    $badFiles += $rel
  }
}
if ($badFiles.Count -gt 0) {
  Fail ('Tracked secret-like files found: ' + (($badFiles | Sort-Object -Unique) -join ', '))
}

$scanExtensions = @('.yaml', '.yml', '.json', '.ps1', '.psm1', '.py', '.md', '.txt', '.cmd', '.bat')
$privateKeyPattern = '-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'
$bearerLiteralPattern = '(?i)\bBearer\s+[A-Za-z0-9._~+/=-]{20,}'
$assignmentPattern = '(?i)^\s*([A-Za-z0-9_.-]*(token|password|passwd|api[_-]?key|secret)[A-Za-z0-9_.-]*)\s*[:=]\s*(.+?)\s*$'
$placeholderPattern = '(?i)(!secret|<[^>]+>|replace_|placeholder|example|change_me|\{\{)|^\s*\$'
$findings = @()

foreach ($rel in $tracked) {
  $normalized = $rel -replace '\\','/'
  if ($normalized.StartsWith('custom_components/', [System.StringComparison]::OrdinalIgnoreCase)) { continue }
  if ($normalized.StartsWith('www/', [System.StringComparison]::OrdinalIgnoreCase)) { continue }
  if ($normalized.StartsWith('docs/security/', [System.StringComparison]::OrdinalIgnoreCase)) { continue }

  $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
  if ($scanExtensions -notcontains $ext) { continue }

  $full = Join-Path $root $rel
  if (-not (Test-Path -LiteralPath $full)) { continue }

  $lineNo = 0
  foreach ($line in Get-Content -LiteralPath $full -ErrorAction Stop) {
    $lineNo++

    if ($line -match $privateKeyPattern) {
      $findings += ('{0}:{1} private-key material' -f $rel, $lineNo)
      continue
    }

    if ($line -match $bearerLiteralPattern) {
      $findings += ('{0}:{1} literal bearer token' -f $rel, $lineNo)
      continue
    }

    $m = [regex]::Match($line, $assignmentPattern)
    if ($m.Success) {
      $value = $m.Groups[3].Value
      if ($value -notmatch $placeholderPattern -and $value -notmatch '^\s*$') {
        $findings += ('{0}:{1} literal sensitive assignment ({2})' -f $rel, $lineNo, $m.Groups[1].Value)
      }
    }
  }
}

if ($findings.Count -gt 0) {
  Write-Host 'SECRET_HYGIENE_FAIL'
  $findings | Sort-Object -Unique | ForEach-Object { Write-Host $_ }
  exit 1
}

Write-Host 'SECRET_HYGIENE_OK'
exit 0
