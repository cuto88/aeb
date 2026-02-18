param(
  [switch]$SkipPush,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$DeployArgs
)

$ErrorActionPreference = "Stop"

function Say($m) { Write-Host $m }

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

if (-not $SkipPush) {
  Say "==> git push"
  git push
  if ($LASTEXITCODE -ne 0) {
    throw "git push failed (RC=$LASTEXITCODE)"
  }
}

Say "==> deploy_safe"
& (Join-Path $PSScriptRoot "deploy_safe.ps1") @DeployArgs
if ($LASTEXITCODE -ne 0) {
  throw "deploy_safe failed (RC=$LASTEXITCODE)"
}

Say "[OK] push_dep completed."
