param(
    [switch]$IncludeWindows,
    [switch]$Rebuild
)

$ErrorActionPreference = 'Stop'

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing required command: $Name"
    }
}

Require-Command -Name docker

$root = Split-Path -Path $PSScriptRoot -Parent
Set-Location $root

$envFile = Join-Path $root '.env.lab'
if (-not (Test-Path $envFile)) {
    $adminUser = 'empireadmin'
    $adminPass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })

    @(
        "EMPIRE_ADMIN_USERNAME=$adminUser"
        "EMPIRE_ADMIN_PASSWORD=$adminPass"
        'EMPIRE_API_HOST_PORT=0'
        'EMPIRE_LISTENER_HOST_PORT=0'
        'UBUNTU_AGENT_LAUNCHER='
        'WINDOWS_AGENT_LAUNCHER='
        'LINUX_VICTIM_LAUNCHER='
        'WINDOWS_VICTIM_LAUNCHER='
    ) | Set-Content -Path $envFile -Encoding ASCII

    Write-Host 'Created .env.lab with randomized Empire admin password.'
}

$buildFlag = if ($Rebuild) { '--no-cache' } else { $null }

Write-Host 'Building Linux-side images...'
$buildEmpireArgs = @('build', '-t', 'c2-labs-empire:latest', '-t', 'empire-c2', '-f', 'Dockerfile', '.')
if ($buildFlag) { $buildEmpireArgs = @('build', '--no-cache', '-t', 'c2-labs-empire:latest', '-t', 'empire-c2', '-f', 'Dockerfile', '.') }
& docker @buildEmpireArgs

$buildUbuntuArgs = @('build', '-t', 'c2-labs-ubuntu-agent:latest', '-f', 'docker/ubuntu-agent/Dockerfile', 'docker/ubuntu-agent')
if ($buildFlag) { $buildUbuntuArgs = @('build', '--no-cache', '-t', 'c2-labs-ubuntu-agent:latest', '-f', 'docker/ubuntu-agent/Dockerfile', 'docker/ubuntu-agent') }
& docker @buildUbuntuArgs

$buildLinuxVictimArgs = @('build', '-t', 'c2-labs-linux-victim:latest', '-f', 'docker/linux-victim/Dockerfile', 'docker/linux-victim')
if ($buildFlag) { $buildLinuxVictimArgs = @('build', '--no-cache', '-t', 'c2-labs-linux-victim:latest', '-f', 'docker/linux-victim/Dockerfile', 'docker/linux-victim') }
& docker @buildLinuxVictimArgs

Write-Host 'Starting Empire + API bridge + Ubuntu agent + Linux victim...'
docker compose --env-file .env.lab up -d empire empire-api-bridge ubuntu-agent linux-victim

$apiBind = docker compose --env-file .env.lab port empire 1337 | Select-Object -First 1
$listenerBind = docker compose --env-file .env.lab port empire 5000 | Select-Object -First 1

$apiPort = if ($apiBind) { ($apiBind -split ':')[-1] } else { $null }
$listenerPort = if ($listenerBind) { ($listenerBind -split ':')[-1] } else { $null }

if ($IncludeWindows) {
    Write-Host 'Building Windows-side images (requires Docker Windows containers mode)...'

    $buildWindowsAgentArgs = @('build', '-t', 'c2-labs-windows-agent:latest', '-f', 'docker/windows-agent/Dockerfile', 'docker/windows-agent')
    if ($buildFlag) { $buildWindowsAgentArgs = @('build', '--no-cache', '-t', 'c2-labs-windows-agent:latest', '-f', 'docker/windows-agent/Dockerfile', 'docker/windows-agent') }
    & docker @buildWindowsAgentArgs

    $buildWindowsVictimArgs = @('build', '-t', 'c2-labs-windows-victim:latest', '-f', 'docker/windows-victim/Dockerfile', 'docker/windows-victim')
    if ($buildFlag) { $buildWindowsVictimArgs = @('build', '--no-cache', '-t', 'c2-labs-windows-victim:latest', '-f', 'docker/windows-victim/Dockerfile', 'docker/windows-victim') }
    & docker @buildWindowsVictimArgs

    Write-Host 'Starting Windows agent + Windows victim...'
    docker compose --env-file .env.lab -f docker-compose.yml -f docker-compose.windows.yml --profile windows up -d windows-agent windows-victim
}

Write-Host ''
Write-Host 'Lab is up.'
if ($apiPort) {
    Write-Host "Empire mapped API port: $apiPort"
}
else {
    Write-Host 'Empire API port mapping not detected. Check: docker compose --env-file .env.lab ps'
}
if ($listenerPort) {
    Write-Host "Empire listener port: $listenerPort"
}
Write-Host 'UI/API compatibility endpoint: http://127.0.0.1:1337'
Write-Host 'Use scripts/run-agent-launcher.ps1 for beacon launchers.'
