$ErrorActionPreference = 'Stop'

$scriptPath = (Resolve-Path (Join-Path $PSScriptRoot '..\deploy_safe.ps1')).Path
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
if ($errors.Count -ne 0) {
  throw "deploy_safe.ps1 has PowerShell parse errors: $($errors.Message -join '; ')"
}

function Assert-RejectedBeforeAccess {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$ExpectedPattern
  )

  $output = & pwsh -NoProfile -File $scriptPath -File $Path -DryRun 2>&1
  if ($LASTEXITCODE -eq 0) { throw "Expected rejection for '$Path'." }
  if (($output -join "`n") -notmatch $ExpectedPattern) {
    throw "Unexpected rejection for '$Path': $($output -join ' ')"
  }
}

Assert-RejectedBeforeAccess -Path '..\secrets.yaml' -ExpectedPattern 'path traversal'
Assert-RejectedBeforeAccess -Path 'configuration.yaml' -ExpectedPattern 'only YAML files directly under packages'
Assert-RejectedBeforeAccess -Path 'packages\nested\bad.yaml' -ExpectedPattern 'only YAML files directly under packages'
Assert-RejectedBeforeAccess -Path 'packages\missing_single_file_test.yaml' -ExpectedPattern 'source not found'
Assert-RejectedBeforeAccess -Path 'C:\Windows\win.ini' -ExpectedPattern 'must be relative'

$source = Get-Content -LiteralPath $scriptPath -Raw
if (-not $source.Contains('if (-not [string]::IsNullOrWhiteSpace($File))')) {
  throw 'Single-file branch guard is missing.'
}
if ($source -notmatch 'Resolve-StaleGitIndexLocks[\s\S]+git fetch origin[\s\S]+git merge --ff-only') {
  throw 'Existing broad deploy Git flow changed unexpectedly.'
}

Write-Host '[OK] deploy_safe single-file tests passed: syntax, traversal, whitelist, missing source, absolute path, broad-flow guard.'

