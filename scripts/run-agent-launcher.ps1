param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ubuntu', 'windows', 'linux-victim', 'windows-victim')]
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

$service = switch ($Target) {
    'ubuntu' { 'ubuntu-agent' }
    'windows' { 'windows-agent' }
    'linux-victim' { 'linux-victim' }
    'windows-victim' { 'windows-victim' }
}
$composeArgs = @('--env-file', '.env.lab')

if ($Target -eq 'windows' -or $Target -eq 'windows-victim') {
    $composeArgs += @('-f', 'docker-compose.yml', '-f', 'docker-compose.windows.yml', '--profile', 'windows')
}

$launcherB64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Launcher))
$containerCmd = "$`$b64='$launcherB64'; $`$cmd=[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($`$b64)); Invoke-Expression $`$cmd"

Write-Host "Running launcher in $service..."
& docker compose @composeArgs exec -T $service pwsh -NoLogo -NoProfile -NonInteractive -Command $containerCmd
