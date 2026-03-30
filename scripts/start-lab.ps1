param(
    [switch]$IncludeWindows
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
        'UBUNTU_AGENT_LAUNCHER='
        'WINDOWS_AGENT_LAUNCHER='
    ) | Set-Content -Path $envFile -Encoding ASCII

    Write-Host "Created .env.lab with randomized Empire admin password."
}

Write-Host 'Starting Empire + Ubuntu agent containers...'
docker compose --env-file .env.lab up -d --build empire ubuntu-agent

if ($IncludeWindows) {
    Write-Host 'Starting Windows agent container (requires Docker in Windows containers mode)...'
    docker compose --env-file .env.lab -f docker-compose.yml -f docker-compose.windows.yml --profile windows up -d --build windows-agent
}

Write-Host ''
Write-Host 'Lab started.'
Write-Host 'Empire API: http://localhost:1337'
Write-Host 'Use scripts/run-agent-launcher.ps1 to launch stagers in ubuntu-agent or windows-agent.'
