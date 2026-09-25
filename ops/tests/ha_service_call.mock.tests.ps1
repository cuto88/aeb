$ErrorActionPreference = 'Stop'

Describe 'M63 shadow service-call contract' {
  BeforeAll {
    . (Join-Path $PSScriptRoot '..\ha_service_call.ps1')
  }

  It 'passes only when HTTP 2xx and the helper becomes on' {
    $script:step = 0
    Mock Invoke-HaHttp {
      $script:step++
      if ($script:step -eq 1) { return [pscustomobject]@{ TransportOk = $true; StatusCode = 200; Body = '{"state":"off"}' } }
      if ($script:step -eq 2) { return [pscustomobject]@{ TransportOk = $true; StatusCode = 200; Body = '[]' } }
      return [pscustomobject]@{ TransportOk = $true; StatusCode = 200; Body = '{"state":"on"}' }
    }
    $result = Invoke-HaShadowEnable -BaseUrl 'http://example.invalid' -Token 'not-printed' -TimeoutSec 1 -IntervalSec 0
    $result.Result | Should Be 'PASS'
    $result.HttpStatus | Should Be 200
    $result.StateAfter | Should Be 'on'
    Assert-MockCalled Invoke-HaHttp -Times 3
  }

  It 'fails on HTTP 401 without retrying the POST' {
    $script:step = 0
    Mock Invoke-HaHttp {
      $script:step++
      if ($script:step -eq 1) { return [pscustomobject]@{ TransportOk = $true; StatusCode = 200; Body = '{"state":"off"}' } }
      return [pscustomobject]@{ TransportOk = $true; StatusCode = 401; Body = '{"message":"unauthorized"}' }
    }
    $result = Invoke-HaShadowEnable -BaseUrl 'http://example.invalid' -Token 'not-printed' -TimeoutSec 1 -IntervalSec 0
    $result.Result | Should Be 'FAIL'
    $result.HttpStatus | Should Be 401
    Assert-MockCalled Invoke-HaHttp -Times 2
  }

  It 'fails when the helper stays off after a successful POST' {
    $script:step = 0
    Mock Invoke-HaHttp {
      $script:step++
      if ($script:step -eq 1) { return [pscustomobject]@{ TransportOk = $true; StatusCode = 200; Body = '{"state":"off"}' } }
      if ($script:step -eq 2) { return [pscustomobject]@{ TransportOk = $true; StatusCode = 200; Body = '[]' } }
      return [pscustomobject]@{ TransportOk = $true; StatusCode = 200; Body = '{"state":"off"}' }
    }
    $result = Invoke-HaShadowEnable -BaseUrl 'http://example.invalid' -Token 'not-printed' -TimeoutSec 0 -IntervalSec 0
    $result.Result | Should Be 'FAIL'
    $result.HttpStatus | Should Be 200
    $result.StateAfter | Should Be 'off'
  }
}
