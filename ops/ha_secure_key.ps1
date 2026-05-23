function Resolve-HaSecureKeyPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $stablePath = Join-Path $PSScriptRoot ".tmp\ha_ed25519.safe"
  if (Test-Path -LiteralPath $stablePath) {
    return $stablePath
  }

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing SSH key: $Path"
  }

  $memRoot = Join-Path $env:USERPROFILE ".codex\memories\ha_keys"
  New-Item -ItemType Directory -Force -Path $memRoot | Out-Null

  $leaf = [System.IO.Path]::GetFileName($Path)
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
  $target = Join-Path $memRoot ($leaf + "." + $stamp + ".temp")

  Copy-Item -LiteralPath $Path -Destination $target -Force

  $principal = (& whoami).Trim()
  $icaclsCmd = @(
    'icacls',
    ('"{0}"' -f $target),
    '/inheritance:r',
    '/grant:r',
    ('"{0}:F"' -f $principal),
    '/grant:r',
    '"SYSTEM:F"',
    '/grant:r',
    '"Administrators:F"',
    '/remove:g',
    '"BUILTIN\Users"',
    '/remove:g',
    '"NT AUTHORITY\Authenticated Users"',
    '/remove:g',
    '"DS-01\CodexSandboxUsers"'
  ) -join ' '
  $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $icaclsCmd -NoNewWindow -PassThru -Wait
  if ($proc.ExitCode -ne 0) {
    throw "Failed to secure SSH key permissions for $target"
  }

  return $target
}
