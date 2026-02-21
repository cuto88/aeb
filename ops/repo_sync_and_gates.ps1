$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    $output = git @Args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git failed: git $($Args -join ' ')"
    }

    return $output
}

Write-Host "==> SYNC + GATES"

try {
    $repoRoot = (Invoke-Git rev-parse --show-toplevel).Trim()
} catch {
    Write-Host "STOP: not inside a git repository."
    exit 1
}

Set-Location $repoRoot

powershell -NoProfile -ExecutionPolicy Bypass -File ops\repo_sync.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: sync failed."
    exit 1
}

# 2. Run validation (repo gates default; optional HA check via -HaCheck)
powershell -NoProfile -ExecutionPolicy Bypass -File ops\validate.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: validation failed."
    exit 1
}

Write-Host "==> OK: repo allineato e validation verde"
