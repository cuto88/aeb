$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\deploy_transport.ps1')

$pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("aeb-transport-test-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null

try {
  $successOutput = Join-Path $testRoot 'success.bin'
  $success = Invoke-AebBoundedProcess -FilePath $pwsh -ArgumentList @('-NoProfile', '-Command', "[Console]::OpenStandardOutput().WriteByte(65)") -OutputFile $successOutput -TimeoutSeconds 5 -HeartbeatSeconds 1 -Label 'success simulation'
  if ($success.ExitCode -ne 0 -or (Get-Item $successOutput).Length -ne 1) { throw 'Success simulation failed.' }

  $nonZero = Invoke-AebBoundedProcess -FilePath $pwsh -ArgumentList @('-NoProfile', '-Command', 'exit 23') -TimeoutSeconds 5 -HeartbeatSeconds 1 -Label 'SSH non-zero simulation'
  if ($nonZero.ExitCode -ne 23) { throw 'SSH non-zero simulation failed.' }

  $tarNonZero = Invoke-AebBoundedProcess -FilePath $pwsh -ArgumentList @('-NoProfile', '-Command', 'exit 2') -TimeoutSeconds 5 -HeartbeatSeconds 1 -Label 'tar non-zero simulation'
  if ($tarNonZero.ExitCode -ne 2) { throw 'Tar non-zero simulation failed.' }

  $timedOut = $false
  try {
    [void](Invoke-AebBoundedProcess -FilePath $pwsh -ArgumentList @('-NoProfile', '-Command', 'Start-Sleep -Seconds 30') -TimeoutSeconds 1 -HeartbeatSeconds 1 -Label 'timeout simulation')
  } catch {
    $timedOut = $_.Exception.Message -match 'timed out'
  }
  if (-not $timedOut) { throw 'Timeout simulation failed.' }

  if (Test-Path (Join-Path $testRoot 'last_deploy.ok')) { throw 'Test unexpectedly created last_deploy.ok.' }
  Write-Host '[OK] deploy transport simulations passed: success, timeout, SSH non-zero, tar non-zero.'
}
finally {
  Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
