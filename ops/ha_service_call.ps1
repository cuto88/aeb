[CmdletBinding()]
param(
  [string]$EnvPath = (Join-Path (Split-Path -Parent $PSScriptRoot) '.env'),
  [int]$StateTimeoutSec = 15,
  [int]$PollIntervalSec = 1
)

$ErrorActionPreference = 'Stop'
$AllowedEndpoint = '/api/services/input_boolean/turn_on'
$AllowedEntity = 'input_boolean.ehw_shadow_enabled'

function Read-DotEnvValue {
  param([string]$Path, [string]$Name)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  foreach ($line in [IO.File]::ReadLines($Path)) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) { continue }
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2 -and $parts[0].Trim() -eq $Name) {
      return $parts[1].Trim().Trim('"').Trim("'")
    }
  }
  return $null
}

function Invoke-HaHttp {
  param(
    [string]$Method,
    [string]$Uri,
    [hashtable]$Headers,
    [string]$Body
  )
  try {
    $params = @{
      Method = $Method
      Uri = $Uri
      Headers = $Headers
      TimeoutSec = 15
      UseBasicParsing = $true
      SkipHttpErrorCheck = $true
    }
    if ($null -ne $Body) {
      $params.ContentType = 'application/json'
      $params.Body = $Body
    }
    $response = Invoke-WebRequest @params
    return [pscustomobject]@{ TransportOk = $true; StatusCode = [int]$response.StatusCode; Body = [string]$response.Content }
  }
  catch {
    return [pscustomobject]@{ TransportOk = $false; StatusCode = $null; Body = $null }
  }
}

function Get-ResponseSummary {
  param([string]$Body)
  if ([string]::IsNullOrEmpty($Body)) { return 'EMPTY' }
  try {
    $parsed = $Body | ConvertFrom-Json
    if ($parsed -is [array]) { return ('JSON_ARRAY_COUNT=' + $parsed.Count) }
    if ($null -ne $parsed.PSObject.Properties) {
      return ('JSON_OBJECT_KEYS=' + (($parsed.PSObject.Properties.Name | Sort-Object) -join ','))
    }
  } catch { }
  return ('TEXT_LENGTH=' + $Body.Length)
}

function Get-HaState {
  param([string]$BaseUrl, [string]$Token, [string]$EntityId)
  $uri = $BaseUrl.TrimEnd('/') + '/api/states/' + [uri]::EscapeDataString($EntityId)
  $result = Invoke-HaHttp -Method Get -Uri $uri -Headers @{ Authorization = ('Bearer ' + $Token) }
  $state = $null
  if ($result.TransportOk -and $result.StatusCode -ge 200 -and $result.StatusCode -lt 300) {
    try { $state = (($result.Body | ConvertFrom-Json).state) } catch { $state = $null }
  }
  return [pscustomobject]@{ Result = $result; State = $state }
}

function Invoke-HaShadowEnable {
  param(
    [string]$BaseUrl,
    [string]$Token,
    [int]$TimeoutSec = 15,
    [int]$IntervalSec = 1
  )
  $started = [DateTime]::UtcNow
  $before = Get-HaState -BaseUrl $BaseUrl -Token $Token -EntityId $AllowedEntity
  if (-not $before.Result.TransportOk -or $before.Result.StatusCode -lt 200 -or $before.Result.StatusCode -ge 300) {
    return [pscustomobject]@{ Result = 'FAIL'; Method = 'POST'; Endpoint = $AllowedEndpoint; Entity = $AllowedEntity; HttpStatus = $null; ExitCode = 1; Response = 'PRESTATE_UNAVAILABLE'; StateBefore = $before.State; StateAfter = $null; DurationSec = 0 }
  }

  $payload = @{ entity_id = $AllowedEntity } | ConvertTo-Json -Compress
  $post = Invoke-HaHttp -Method Post -Uri ($BaseUrl.TrimEnd('/') + $AllowedEndpoint) -Headers @{ Authorization = ('Bearer ' + $Token) } -Body $payload
  if (-not $post.TransportOk -or $post.StatusCode -lt 200 -or $post.StatusCode -ge 300) {
    return [pscustomobject]@{ Result = 'FAIL'; Method = 'POST'; Endpoint = $AllowedEndpoint; Entity = $AllowedEntity; HttpStatus = $post.StatusCode; ExitCode = 1; Response = (Get-ResponseSummary $post.Body); StateBefore = $before.State; StateAfter = $null; DurationSec = ([DateTime]::UtcNow - $started).TotalSeconds }
  }

  $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSec)
  $after = $null
  do {
    $after = Get-HaState -BaseUrl $BaseUrl -Token $Token -EntityId $AllowedEntity
    if ($after.State -eq 'on') {
      return [pscustomobject]@{ Result = 'PASS'; Method = 'POST'; Endpoint = $AllowedEndpoint; Entity = $AllowedEntity; HttpStatus = $post.StatusCode; ExitCode = 0; Response = (Get-ResponseSummary $post.Body); StateBefore = $before.State; StateAfter = $after.State; DurationSec = ([DateTime]::UtcNow - $started).TotalSeconds }
    }
    if ([DateTime]::UtcNow -lt $deadline) { Start-Sleep -Seconds $IntervalSec }
  } while ([DateTime]::UtcNow -lt $deadline)

  return [pscustomobject]@{ Result = 'FAIL'; Method = 'POST'; Endpoint = $AllowedEndpoint; Entity = $AllowedEntity; HttpStatus = $post.StatusCode; ExitCode = 1; Response = (Get-ResponseSummary $post.Body); StateBefore = $before.State; StateAfter = $after.State; DurationSec = ([DateTime]::UtcNow - $started).TotalSeconds }
}

if ($MyInvocation.InvocationName -ne '.') {
  $baseUrl = Read-DotEnvValue -Path $EnvPath -Name 'HA_URL'
  $token = Read-DotEnvValue -Path $EnvPath -Name 'HA_TOKEN'
  if ([string]::IsNullOrWhiteSpace($baseUrl) -or [string]::IsNullOrWhiteSpace($token)) {
    Write-Output 'RESULT=FAIL ERROR=API_CREDENTIAL_PROVISIONING_REQUIRED'
    exit 3
  }
  $outcome = Invoke-HaShadowEnable -BaseUrl $baseUrl -Token $token -TimeoutSec $StateTimeoutSec -IntervalSec $PollIntervalSec
  $outcome | ConvertTo-Json -Compress
  exit ([int]$outcome.ExitCode)
}
