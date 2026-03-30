$ErrorActionPreference = 'Stop'

if ($env:BEACON_LAUNCHER -and $env:BEACON_LAUNCHER.Trim().Length -gt 0) {
    Write-Host '[windows-victim] Executing beacon launcher from environment'
    Invoke-Expression $env:BEACON_LAUNCHER
}
else {
    Write-Host '[windows-victim] No beacon launcher set. Waiting for operator command.'
}

while ($true) {
    Start-Sleep -Seconds 60
}
