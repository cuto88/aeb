param(
  [string]$RemoteCommand = "",
  [int]$Port = 2222,
  [string]$HaHost = "root@192.168.178.84",
  [string]$KeyPath = $(if ($env:HA_SSH_KEY_PATH) { $env:HA_SSH_KEY_PATH } elseif (Test-Path -LiteralPath "C:\2_OPS\aeb\.tmp\ha_ed25519.safe") { "C:\2_OPS\aeb\.tmp\ha_ed25519.safe" } elseif (Test-Path -LiteralPath "C:\2_OPS\secrets\ha\ha_ed25519") { "C:\2_OPS\secrets\ha\ha_ed25519" } elseif (Test-Path -LiteralPath "C:\2_OPS\secrets\ha\ha_fallback_ed25519") { "C:\2_OPS\secrets\ha\ha_fallback_ed25519" } else { "C:\Users\randalab\.ssh\ha_ed25519" })
)

$ErrorActionPreference = 'Stop'

function New-SafeSshKeyCopy {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath
  )

  if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "SSH key source not found: $SourcePath"
  }

  $tmpRoot = Join-Path -Path $PSScriptRoot -ChildPath ".tmp"
  if (-not (Test-Path -LiteralPath $tmpRoot)) {
    New-Item -ItemType Directory -Path $tmpRoot | Out-Null
  }

  $safePath = Join-Path -Path $tmpRoot -ChildPath ("ha_ed25519.safe.{0}" -f ([guid]::NewGuid().ToString('N')))
  Copy-Item -LiteralPath $SourcePath -Destination $safePath -Force

  $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $acl = New-Object System.Security.AccessControl.FileSecurity
  $acl.SetAccessRuleProtection($true, $false)
  $ruleUser = [System.Security.AccessControl.FileSystemAccessRule]::new($currentUser, [System.Security.AccessControl.FileSystemRights]::Modify, [System.Security.AccessControl.AccessControlType]::Allow)
  $ruleSystem = [System.Security.AccessControl.FileSystemAccessRule]::new('NT AUTHORITY\SYSTEM', [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow)
  $ruleAdmins = [System.Security.AccessControl.FileSystemAccessRule]::new('BUILTIN\Administrators', [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow)
  $rules = @($ruleUser, $ruleSystem, $ruleAdmins)
  foreach ($rule in $rules) {
    [void]$acl.AddAccessRule($rule)
  }
  Set-Acl -LiteralPath $safePath -AclObject $acl

  return $safePath
}

$safeKeyPath = $null
try {
  if ($KeyPath -and (Split-Path -Leaf $KeyPath) -eq "ha_ed25519.safe") {
    $safeKeyPath = $KeyPath
  } else {
    $safeKeyPath = New-SafeSshKeyCopy -SourcePath $KeyPath
  }

  $sshArgs = @(
    '-T'
    '-o', 'UserKnownHostsFile=C:\2_OPS\secrets\ha\known_hosts'
    '-o', 'StrictHostKeyChecking=yes'
    '-p', $Port
    '-i', $safeKeyPath
    $HaHost
  )
  if ($RemoteCommand -and $RemoteCommand.Trim()) {
    $sshArgs += $RemoteCommand
  }

  & ssh @sshArgs
  exit $LASTEXITCODE
}
finally {
  if ($safeKeyPath -and $safeKeyPath -ne $KeyPath -and (Test-Path -LiteralPath $safeKeyPath)) {
    Remove-Item -LiteralPath $safeKeyPath -Force
  }
}
