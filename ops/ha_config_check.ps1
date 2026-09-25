[CmdletBinding()]
param(
  [string]$SshHost = 'dscomparin@192.168.178.110',
  [string]$Container = 'homeassistant',
  [string]$ConfigPath = '/config',
  [int]$TimeoutSec = 300,
  [string]$EvidencePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts\m63_config_check.json'),
  [switch]$NoExecute
)

$ErrorActionPreference = 'Stop'

function Sanitize-Text {
  param([AllowNull()][string]$Text)
  if ($null -eq $Text) { return '' }
  $safe = $Text -replace '(?im)(authorization\s*[:=]\s*|bearer\s+|token\s*[:=]\s*|password\s*[:=]\s*|secret\s*[:=]\s*)[^\s,;]+', '$1[REDACTED]'
  if ($safe.Length -gt 20000) { return $safe.Substring(0, 20000) + "`n[TRUNCATED]" }
  return $safe
}

function Classify-Exit {
  param([int]$ExitCode, [bool]$TimedOut)
  if ($TimedOut -or $ExitCode -eq 124) { return 'CONFIG_CHECK_TIMEOUT' }
  if ($ExitCode -eq 0) { return 'CONFIG_CHECK_PASS' }
  return 'CONFIG_CHECK_FAIL'
}

function Write-EvidenceAtomic {
  param([Parameter(Mandatory)][psobject]$Evidence, [Parameter(Mandatory)][string]$Path)
  $full = [IO.Path]::GetFullPath($Path)
  $parent = Split-Path -Parent $full
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  $temp = "$full.tmp.$([guid]::NewGuid().ToString('N'))"
  try {
    $json = $Evidence | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($temp, $json, [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $full -Force
  } finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
  }
  return $full
}

function Invoke-SshCapture {
  param([Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][int]$TimeoutSeconds)
  $sshPath = 'C:\Windows\System32\OpenSSH\ssh.exe'
  if (-not (Test-Path -LiteralPath $sshPath)) { throw "OpenSSH executable not found: $sshPath" }
  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $sshPath
  foreach ($arg in $Arguments) { [void]$psi.ArgumentList.Add($arg) }
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
    [pscustomobject]@{
      StartUtc = $start
      EndUtc = [DateTime]::UtcNow
      DurationSec = [math]::Round(([DateTime]::UtcNow - $start).TotalSeconds, 3)
      StdOut = Sanitize-Text $stdout
      StdErr = Sanitize-Text $stderr
      ExitCode = if ($timedOut) { 124 } else { $process.ExitCode }
      TimedOut = $timedOut
    }
  } finally { $process.Dispose() }
}

function Invoke-ConfigCheck {
  param([string]$Target, [string]$ContainerName, [string]$Path, [int]$TimeoutSeconds, [string]$OutputPath)
  if ($TimeoutSeconds -lt 300) { throw 'TimeoutSec must be at least 300 seconds.' }
  $preflight = Invoke-SshCapture -Arguments @('-o','BatchMode=yes',$Target,'hostname && whoami') -TimeoutSeconds 30
  $remote = 'docker exec ' + $ContainerName + ' hass --script check_config --config ' + $Path
  if ($preflight.TimedOut -or $preflight.ExitCode -ne 0) {
    $evidence = [pscustomobject]@{
      schema_version = 1; started_utc = $preflight.StartUtc.ToString('o'); finished_utc = $preflight.EndUtc.ToString('o'); duration_seconds = $preflight.DurationSec
      ssh_preflight = 'FAIL'; command = "C:\Windows\System32\OpenSSH\ssh.exe -o BatchMode=yes $Target `"$remote`""
      stdout = $preflight.StdOut; stderr = $preflight.StdErr; exit_code = $preflight.ExitCode; timed_out = $preflight.TimedOut; classification = 'SSH_PREFLIGHT_FAIL'
    }
    return [pscustomobject]@{ Evidence = $evidence; ExitCode = if ($preflight.TimedOut) { 124 } else { 1 } }
  }
  $result = Invoke-SshCapture -Arguments @('-o','BatchMode=yes',$Target,$remote) -TimeoutSeconds $TimeoutSeconds
  $classification = Classify-Exit -ExitCode $result.ExitCode -TimedOut $result.TimedOut
  $evidence = [pscustomobject]@{
    schema_version = 1; started_utc = $result.StartUtc.ToString('o'); finished_utc = $result.EndUtc.ToString('o'); duration_seconds = $result.DurationSec
    ssh_preflight = 'PASS'; command = "C:\Windows\System32\OpenSSH\ssh.exe -o BatchMode=yes $Target `"$remote`""
    stdout = $result.StdOut; stderr = $result.StdErr; exit_code = $result.ExitCode; timed_out = $result.TimedOut; classification = $classification
    warning = if ([string]::IsNullOrWhiteSpace($result.StdOut) -and $classification -eq 'CONFIG_CHECK_PASS') { 'STDOUT_EMPTY' } else { $null }
  }
  return [pscustomobject]@{ Evidence = $evidence; ExitCode = if ($classification -eq 'CONFIG_CHECK_TIMEOUT') { 124 } elseif ($classification -eq 'CONFIG_CHECK_PASS') { 0 } else { 1 } }
}

if (-not $NoExecute -and $MyInvocation.InvocationName -ne '.') {
  $run = Invoke-ConfigCheck -Target $SshHost -ContainerName $Container -Path $ConfigPath -TimeoutSeconds $TimeoutSec -OutputPath $EvidencePath
  $written = Write-EvidenceAtomic -Evidence $run.Evidence -Path $EvidencePath
  Write-Output ("classification=" + $run.Evidence.classification)
  Write-Output ("exit_code=" + $run.Evidence.exit_code)
  Write-Output ("timed_out=" + $run.Evidence.timed_out)
  Write-Output ("evidence_path=" + $written)
  exit $run.ExitCode
}
