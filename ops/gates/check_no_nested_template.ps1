param(
  [string]$RepoRoot = (Resolve-Path ".")
)

Write-Host "Gate: check_no_nested_template"

$files = Get-ChildItem -Path "$RepoRoot/packages" -Recurse -Include *.yaml,*.yml -File
$errors = New-Object System.Collections.Generic.List[string]

foreach ($f in $files) {
  $lines = Get-Content -LiteralPath $f.FullName
  $inTemplateRoot = $false
  $templateIndent = 0

  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    # skip comments/empty
    if ($line -match '^\s*(#.*)?$') { continue }

    # enter template: root block
    if (-not $inTemplateRoot -and $line -match '^(\s*)template:\s*$') {
      $inTemplateRoot = $true
      $templateIndent = $Matches[1].Length
      continue
    }

    if ($inTemplateRoot) {
      # exit template block when indentation goes back to <= templateIndent and line is a new key
      if ($line -match '^(\s*)\S' -and $Matches[1].Length -le $templateIndent -and $line -notmatch '^\s*-\s') {
        $inTemplateRoot = $false
        $templateIndent = 0
        # keep scanning this line as normal
      } else {
        # detect nested template list item
        if ($line -match '^\s*-\s*template:\s*$') {
          $errors.Add("$($f.FullName):$($i+1) nested '- template:' inside root template block")
        }
      }
    }
  }
}

if ($errors.Count -gt 0) {
  Write-Host "FAIL: Nested template blocks detected:" -ForegroundColor Red
  $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  exit 1
}

Write-Host "OK: No nested template blocks."
exit 0
