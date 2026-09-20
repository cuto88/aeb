param(
  [string]$RepoRoot = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepoRoot).Path

function Fail([string]$Message) {
  Write-Error $Message
  exit 1
}

$tracked = @()
try {
  $raw = & git -C $root ls-files -z 2>$null
  if ($LASTEXITCODE -eq 0 -and $raw) {
    $tracked = $raw -split "`0" | Where-Object { $_ }
  }
} catch {
  $tracked = @()
}

if ($tracked.Count -eq 0) {
  Fail 'Secret hygiene gate requires a Git working tree with tracked-file metadata.'
}

$forbiddenNames = @(
  'secrets.yaml',
  '.env',
  'id_rsa',
  'id_ed25519'
)

$forbiddenExtensions = @('.pem', '.p12', '.pfx')
$badFiles = New-Object System.Collections.Generic.List[string]

foreach ($rel in $tracked) {
  $leaf = [System.IO.Path]::GetFileName($rel)
  $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()

  if ($forbiddenNames -contains $leaf -or $forbiddenExtensions -contains $ext) {
    $badFiles.Add($rel)
  }
}

if ($badFiles.Count -gt 0) {
  Fail ('Tracked secret-like files found: ' + (($badFiles | Sort-Object -Unique) -join ', '))
}

$scanExtensions = @('.yaml', '.yml', '.json', '.ps1', '.psm1', '.py', '.md', '.txt', '.cmd', '.bat')
$excludedPrefixes = @(
  'custom_components/',
  'www/',
  'docs/security/'
)

$privateKeyPattern = '-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'
$bearerLiteralPattern = '(?i)\bBearer\s+[A-Za-z0-9._~+/=-]{20,}'
$assignmentPattern = '(?i)^\s*([A-Za-z0-9_.-]*(token|password|passwd|api[_-]?key|secret)[A-Za-z0-9_.-]*)\s*[:=]\s*(.+?)\s*$'
$placeholderPattern = '(?i)(!secret|<[^>]+>|replace_|placeholder|example|change_me|\{\{)|^\s*\

$findings = New-Object System.Collections.Generic.List[string]

foreach ($rel in $tracked) {
  $normalized = $rel -replace '\\','/'
  if ($excludedPrefixes | Where-Object { $normalized.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase) }) {
    continue
  }

  $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
  if ($scanExtensions -notcontains $ext) {
    continue
  }

  $full = Join-Path $root $rel
  if (-not (Test-Path -LiteralPath $full)) {
    continue
  }

  $lineNo = 0
  foreach ($line in Get-Content -LiteralPath $full -ErrorAction Stop) {
    $lineNo++

    if ($line -match $privateKeyPattern) {
      $findings.Add("${rel}:$lineNo private-key material")
      continue
    }

    if ($line -match $bearerLiteralPattern -and $line -notmatch '\$env:') {
      $findings.Add("${rel}:$lineNo literal bearer token")
      continue
    }

    $m = [regex]::Match($line, $assignmentPattern)
    if ($m.Success) {
      $value = $m.Groups[3].Value
      if ($value -notmatch $placeholderPattern -and $value -notmatch '^\s*$') {
        $findings.Add("${rel}:$lineNo literal sensitive assignment ($($m.Groups[1].Value))")
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


$findings = New-Object System.Collections.Generic.List[string]

foreach ($rel in $tracked) {
  $normalized = $rel -replace '\\','/'
  if ($excludedPrefixes | Where-Object { $normalized.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase) }) {
    continue
  }

  $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
  if ($scanExtensions -notcontains $ext) {
    continue
  }

  $full = Join-Path $root $rel
  if (-not (Test-Path -LiteralPath $full)) {
    continue
  }

  $lineNo = 0
  foreach ($line in Get-Content -LiteralPath $full -ErrorAction Stop) {
    $lineNo++

    if ($line -match $privateKeyPattern) {
      $findings.Add("${rel}:$lineNo private-key material")
      continue
    }

    if ($line -match $bearerLiteralPattern -and $line -notmatch '\$env:') {
      $findings.Add("${rel}:$lineNo literal bearer token")
      continue
    }

    $m = [regex]::Match($line, $assignmentPattern)
    if ($m.Success) {
      $value = $m.Groups[3].Value
      if ($value -notmatch $placeholderPattern -and $value -notmatch '^\s*$') {
        $findings.Add("${rel}:$lineNo literal sensitive assignment ($($m.Groups[1].Value))")
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
