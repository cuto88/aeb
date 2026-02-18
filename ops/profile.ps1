# PowerShell shortcuts for Casa Mercurio ops.
#
# Keep this file self-contained so it can be dot-sourced from $PROFILE.
# Update $HA_REPO if the repo path changes.

$HA_REPO = "F:\01_PROJECT\home-assistant\casa-mercurio-codex-2025"

function Invoke-HaOpsScript {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptName,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
  )

  $scriptPath = Join-Path $HA_REPO "ops\$ScriptName"
  if (-not (Test-Path $scriptPath)) {
    Write-Warning "HA ops script not found: $scriptPath"
    return 2
  }

  $ps = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    "pwsh"
  } elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
    "powershell"
  } else {
    Write-Warning "No PowerShell host found (pwsh/powershell)."
    return 3
  }

  & $ps -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Args
  return $LASTEXITCODE
}

function ha-sync {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  return Invoke-HaOpsScript -ScriptName "repo_sync.ps1" -Args $Args
}

function ha-gates {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  return Invoke-HaOpsScript -ScriptName "validate.ps1" -Args $Args
}

function ha-validate {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  return Invoke-HaOpsScript -ScriptName "validate.ps1" -Args $Args
}

function ha-gates-ci {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  return Invoke-HaOpsScript -ScriptName "gates_run_ci.ps1" -Args $Args
}

function ha-deploy {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  return Invoke-HaOpsScript -ScriptName "deploy_safe.ps1" -Args $Args
}

function ha-push-dep {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  return Invoke-HaOpsScript -ScriptName "push_dep.ps1" -Args $Args
}

function ha-flow {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  $rc = Invoke-HaOpsScript -ScriptName "repo_sync.ps1" -Args $Args
  if ($rc -eq 0) {
    $rc = Invoke-HaOpsScript -ScriptName "validate.ps1" -Args $Args
  }
  if ($rc -eq 0) {
    $rc = Invoke-HaOpsScript -ScriptName "deploy_safe.ps1" -Args $Args
  }

  return $rc
}

function dep! {
  [CmdletBinding()]
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

  $rc = Invoke-HaOpsScript -ScriptName "validate.ps1" -Args $Args
  if ($rc -eq 0) {
    $rc = Invoke-HaOpsScript -ScriptName "deploy_safe.ps1" -Args $Args
  }

  return $rc
}

Set-Alias sync ha-sync
Set-Alias gates ha-gates
Set-Alias validate ha-validate
Set-Alias push_dep ha-push-dep
Set-Alias flow ha-flow
