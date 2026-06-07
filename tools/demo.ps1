$setStatus = Join-Path $PSScriptRoot "set-status.ps1"

& $setStatus running "Agent is working"
Start-Sleep -Seconds 3
& $setStatus waiting "Approval required"
Start-Sleep -Seconds 3
& $setStatus done "Task completed"
