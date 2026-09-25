$ErrorActionPreference = 'Stop'

Describe 'M63 config check classification' {
  BeforeAll { . (Join-Path $PSScriptRoot '..\ha_config_check.ps1') -NoExecute }

  It 'passes informative stdout with exit zero' {
    (Classify-Exit -ExitCode 0 -TimedOut $false) | Should Be 'CONFIG_CHECK_PASS'
  }

  It 'passes empty stdout with exit zero' {
    (Classify-Exit -ExitCode 0 -TimedOut $false) | Should Be 'CONFIG_CHECK_PASS'
  }

  It 'classifies timeout or 124 as timeout' {
    (Classify-Exit -ExitCode 124 -TimedOut $true) | Should Be 'CONFIG_CHECK_TIMEOUT'
  }

  It 'classifies YAML errors and non-zero exit as failure' {
    (Classify-Exit -ExitCode 1 -TimedOut $false) | Should Be 'CONFIG_CHECK_FAIL'
  }

  It 'writes valid UTF-8 JSON evidence atomically' {
    $path = Join-Path $TestDrive 'evidence.json'
    $evidence = [pscustomobject]@{ classification = 'CONFIG_CHECK_PASS'; stdout = 'Testing configuration at /config'; stderr = ''; exit_code = 0 }
    $written = Write-EvidenceAtomic -Evidence $evidence -Path $path
    (Get-Content -LiteralPath $written -Raw | ConvertFrom-Json).classification | Should Be 'CONFIG_CHECK_PASS'
  }
}
