$ErrorActionPreference = 'Stop'

function Invoke-AebBoundedProcess {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string]$InputFile,
    [string]$OutputFile,
    [int]$TimeoutSeconds = 300,
    [int]$HeartbeatSeconds = 15,
    [string]$Label = 'process'
  )

  if ($TimeoutSeconds -lt 1) { throw 'TimeoutSeconds must be positive.' }
  if ($HeartbeatSeconds -lt 1) { throw 'HeartbeatSeconds must be positive.' }

  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $FilePath
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardInput = [bool]$InputFile
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  if ($startInfo.PSObject.Properties.Name -notcontains 'ArgumentList') {
    throw 'The SSH deploy transport requires PowerShell 7 / modern .NET (ProcessStartInfo.ArgumentList).'
  }
  foreach ($argument in $ArgumentList) {
    [void]$startInfo.ArgumentList.Add($argument)
  }

  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  $inputStream = $null
  $outputStream = $null
  $inputTask = $null
  $outputTask = $null
  $stdoutTask = $null
  $stderrTask = $null
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

  try {
    if (-not $process.Start()) { throw "Unable to start $Label." }
    $stderrTask = $process.StandardError.ReadToEndAsync()

    if ($OutputFile) {
      $outputStream = [System.IO.File]::Open($OutputFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
      $outputTask = $process.StandardOutput.BaseStream.CopyToAsync($outputStream)
    } else {
      $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    }

    if ($InputFile) {
      $inputStream = [System.IO.File]::OpenRead($InputFile)
      $inputTask = $inputStream.CopyToAsync($process.StandardInput.BaseStream)
    }

    $nextHeartbeat = $HeartbeatSeconds
    $stdinClosed = -not $InputFile
    while (-not $process.HasExited) {
      if ($inputTask -and $inputTask.IsCompleted -and -not $stdinClosed) {
        $inputTask.GetAwaiter().GetResult()
        $process.StandardInput.Close()
        $stdinClosed = $true
      }
      if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
        try { $process.Kill($true) } catch { }
        $process.WaitForExit()
        throw "$Label timed out after $TimeoutSeconds seconds. Child process tree terminated."
      }
      if ($stopwatch.Elapsed.TotalSeconds -ge $nextHeartbeat) {
        Write-Host ("[heartbeat] {0}: {1:n0}s elapsed" -f $Label, $stopwatch.Elapsed.TotalSeconds)
        $nextHeartbeat += $HeartbeatSeconds
      }
      Start-Sleep -Milliseconds 200
    }

    if ($inputTask) { $inputTask.GetAwaiter().GetResult() }
    if (-not $stdinClosed) { $process.StandardInput.Close() }
    if ($outputTask) { $outputTask.GetAwaiter().GetResult() }
    $stdout = if ($stdoutTask) { $stdoutTask.GetAwaiter().GetResult() } else { '' }
    $stderr = $stderrTask.GetAwaiter().GetResult()

    [pscustomobject]@{
      ExitCode = $process.ExitCode
      Stdout = $stdout
      Stderr = $stderr
      DurationSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
    }
  }
  finally {
    if ($inputStream) { $inputStream.Dispose() }
    if ($outputStream) { $outputStream.Dispose() }
    if ($process -and -not $process.HasExited) {
      try { $process.Kill($true) } catch { }
      try { $process.WaitForExit() } catch { }
    }
    if ($process) { $process.Dispose() }
    $stopwatch.Stop()
  }
}

function Get-AebSshArguments {
  param(
    [Parameter(Mandatory = $true)][string]$KeyPath,
    [Parameter(Mandatory = $true)][string]$KnownHostsPath,
    [Parameter(Mandatory = $true)][string]$RemoteHostName,
    [Parameter(Mandatory = $true)][int]$Port,
    [Parameter(Mandatory = $true)][string]$RemoteCommand,
    [int]$ConnectTimeoutSeconds = 10
  )

  @(
    '-T',
    '-o', 'BatchMode=yes',
    '-o', "ConnectTimeout=$ConnectTimeoutSeconds",
    '-o', 'ConnectionAttempts=1',
    '-o', 'ServerAliveInterval=15',
    '-o', 'ServerAliveCountMax=2',
    '-o', "UserKnownHostsFile=$KnownHostsPath",
    '-o', 'StrictHostKeyChecking=yes',
    '-p', [string]$Port,
    '-i', $KeyPath,
    $RemoteHostName,
    $RemoteCommand
  )
}
