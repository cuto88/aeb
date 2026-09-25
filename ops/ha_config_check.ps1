[CmdletBinding()]
param(
  [string]$SshHost = 'dscomparin@192.168.178.110',
  [string]$Container = 'homeassistant',
  [string]$ConfigPath = '/config',
  [int]$TimeoutSec = 300,
  [switch]$NoExecute
)

$ErrorActionPreference = 'Stop'

function Sanitize-Output {
  param([AllowNull()][string]$Text)
  if ($null -eq $Text) { return '' }
  $safe = $Text -replace '(?im)(authorization\s*[:=]\s*|bearer\s+|token\s*[:=]\s*|password\s*[:=]\s*|secret\s*[:=]\s*)[^\s,;]+', '$1[REDACTED]'
  if ($safe.Length -gt 20000) { return $safe.Substring(0, 20000) + "`n[TRUNCATED]" }
  return $safe
}

function Classify-ConfigCheckResult {
  param(
    [bool]$TimedOut,
    [int]$SshExitCode,
    [Nullable[int]]$RemoteExitCode,
    [string]$StdErr,
    [bool]$TransportError = $false
  )
  if ($TimedOut -or $SshExitCode -eq 124 -or $RemoteExitCode -eq 124) { return 'CONFIG_CHECK_TIMEOUT' }
  if ($TransportError -or $null -eq $RemoteExitCode -or $SshExitCode -ne 0 -or $RemoteExitCode -ne 0) { return 'CONFIG_CHECK_FAIL' }
  if ($StdErr -match '(?im)(error|exception|failed|invalid\s+config|yaml.*(error|invalid)|traceback)') { return 'CONFIG_CHECK_FAIL' }
  return 'CONFIG_CHECK_PASS'
}

function Invoke-ConfigCheck {
  param(
    [string]$Target,
    [string]$ContainerName,
    [string]$Path,
    [int]$TimeoutSeconds
  )
  if ($TimeoutSeconds -lt 300) { throw 'TimeoutSec must be at least 300 seconds.' }
  $sshPath = (Get-Command ssh -ErrorAction Stop).Source
  $remoteCommand = 'docker exec ' + $ContainerName + ' hass --script check_config --config ' + $Path + '; rc=$?; printf "`n__M63_REMOTE_EXIT__=%s`n" "$rc"; exit "$rc"'
  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $sshPath
  foreach ($arg in @('-o','BatchMode=yes',$Target,$remoteCommand)) { [void]$psi.ArgumentList.Add($arg) }
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $psi
  $start = [DateTime]::UtcNow
  try {
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $finished = $process.WaitForExit($TimeoutSeconds * 1000)
    $timedOut = -not $finished
    if ($timedOut) {
      try { $process.Kill($true) } catch { }
      $process.WaitForExit()
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $sshExit = if ($timedOut) { 124 } else { $process.ExitCode }
    $remoteExit = $null
    if ($stdout -match '__M63_REMOTE_EXIT__=(\d+)') {
      $remoteExit = [int]$Matches[1]
      $stdout = [regex]::Replace($stdout, '(?m)^__M63_REMOTE_EXIT__=\d+\s*$', '').Trim()
    }
    $transportError = ($sshExit -eq 255 -and $null -eq $remoteExit)
    $result = Classify-ConfigCheckResult -TimedOut $timedOut -SshExitCode $sshExit -RemoteExitCode $remoteExit -StdErr $stderr -TransportError $transportError
    return [pscustomobject]@{
      Result = $result
      StartUtc = $start.ToString('o')
      EndUtc = [DateTime]::UtcNow.ToString('o')
      DurationSec = [math]::Round(([DateTime]::UtcNow - $start).TotalSeconds, 3)
      TimeoutSec = $TimeoutSeconds
      TimedOut = $timedOut
      SshExitCode = $sshExit
      RemoteExitCode = $remoteExit
      StdOut = Sanitize-Output $stdout
      StdErr = Sanitize-Output $stderr
      Warning = if ([string]::IsNullOrWhiteSpace($stdout) -and $result -eq 'CONFIG_CHECK_PASS') { 'STDOUT_EMPTY' } else { $null }
    }
  }
  finally { $process.Dispose() }
}

if (-not $NoExecute -and $MyInvocation.InvocationName -ne '.') {
  $outcome = Invoke-ConfigCheck -Target $SshHost -ContainerName $Container -Path $ConfigPath -TimeoutSeconds $TimeoutSec
  $outcome | ConvertTo-Json -Compress
  if ($outcome.Result -eq 'CONFIG_CHECK_TIMEOUT') { exit 124 }
  if ($outcome.Result -ne 'CONFIG_CHECK_PASS') { exit 1 }
  exit 0
}
