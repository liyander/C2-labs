$ErrorActionPreference = 'Stop'

if ($env:AGENT_LAUNCHER -and $env:AGENT_LAUNCHER.Trim().Length -gt 0) {
    Write-Host '[windows-agent] Executing launcher from environment'
    Invoke-Expression $env:AGENT_LAUNCHER
}
else {
    Write-Host '[windows-agent] No launcher set. Container will stay alive for manual operations.'
}

while ($true) {
    Start-Sleep -Seconds 60
}
