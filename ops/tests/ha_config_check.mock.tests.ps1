$ErrorActionPreference = 'Stop'

Describe 'M63 config check classification' {
  BeforeAll { . (Join-Path $PSScriptRoot '..\ha_config_check.ps1') -NoExecute }

  It 'passes informative stdout with remote and SSH exit zero' {
    (Classify-ConfigCheckResult -TimedOut $false -SshExitCode 0 -RemoteExitCode 0 -StdErr '') | Should Be 'CONFIG_CHECK_PASS'
  }

  It 'classifies timeout or 124 as timeout' {
    (Classify-ConfigCheckResult -TimedOut $true -SshExitCode 124 -RemoteExitCode 124 -StdErr '') | Should Be 'CONFIG_CHECK_TIMEOUT'
  }

  It 'classifies YAML errors and non-zero remote exit as failure' {
    (Classify-ConfigCheckResult -TimedOut $false -SshExitCode 1 -RemoteExitCode 1 -StdErr 'YAML error') | Should Be 'CONFIG_CHECK_FAIL'
  }

  It 'classifies SSH transport failure separately as failure' {
    (Classify-ConfigCheckResult -TimedOut $false -SshExitCode 255 -RemoteExitCode $null -StdErr 'Permission denied' -TransportError $true) | Should Be 'CONFIG_CHECK_FAIL'
  }

  It 'passes empty stdout with a warning handled by the caller' {
    (Classify-ConfigCheckResult -TimedOut $false -SshExitCode 0 -RemoteExitCode 0 -StdErr '') | Should Be 'CONFIG_CHECK_PASS'
  }
}
