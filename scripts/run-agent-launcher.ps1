param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ubuntu', 'windows')]
    [string]$Target,

    [Parameter(Mandatory = $true)]
    [string]$Launcher
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Path $PSScriptRoot -Parent
Set-Location $root

if (-not (Test-Path '.env.lab')) {
    throw 'Missing .env.lab. Run scripts/start-lab.ps1 first.'
}

$service = if ($Target -eq 'ubuntu') { 'ubuntu-agent' } else { 'windows-agent' }
$composeArgs = @('--env-file', '.env.lab')

if ($Target -eq 'windows') {
    $composeArgs += @('-f', 'docker-compose.yml', '-f', 'docker-compose.windows.yml', '--profile', 'windows')
}

$launcherB64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Launcher))
$containerCmd = "$`$b64='$launcherB64'; $`$cmd=[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($`$b64)); Invoke-Expression $`$cmd"

Write-Host "Running launcher in $service..."
& docker compose @composeArgs exec -T $service pwsh -NoLogo -NoProfile -NonInteractive -Command $containerCmd
