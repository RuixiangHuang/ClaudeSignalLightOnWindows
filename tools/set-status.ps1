param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet("running", "waiting", "done")]
    [string]$Status,

    [Parameter(Position = 1)]
    [string]$Message = "",

    [string]$StatePath = (Join-Path (Split-Path -Parent $PSScriptRoot) "runtime\status.json")
)

$directory = Split-Path -Parent $StatePath
New-Item -ItemType Directory -Path $directory -Force | Out-Null

$state = [ordered]@{
    status = $Status
    message = $Message
    updatedAt = [DateTimeOffset]::Now.ToString("o")
    processId = $PID
}

$temporaryPath = "$StatePath.tmp"
$state | ConvertTo-Json | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
Move-Item -LiteralPath $temporaryPath -Destination $StatePath -Force

Write-Output "CodeAgentLight: $Status"
