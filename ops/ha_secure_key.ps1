function Resolve-HaSecureKeyPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
    throw "Missing SSH key: $Path"
  }

  $tmpRoot = Join-Path $PSScriptRoot ".tmp"
  New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null

  $leaf = [System.IO.Path]::GetFileName($Path)
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
  $target = Join-Path $tmpRoot ($leaf + "." + $stamp + ".temp")

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
    '"NT AUTHORITY\Authenticated Users"'
  ) -join ' '
  $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $icaclsCmd -NoNewWindow -PassThru -Wait
  if ($proc.ExitCode -ne 0) {
    throw "Failed to secure SSH key permissions for $target"
  }

  return $target
}
