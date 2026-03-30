param(
    [switch]$RemoveAgentImages
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Path $PSScriptRoot -Parent
Set-Location $root

if (Test-Path '.env.lab') {
    Write-Host 'Stopping Linux lab services...'
    docker compose --env-file .env.lab down --volumes --remove-orphans

    Write-Host 'Stopping Windows agent profile if present...'
    docker compose --env-file .env.lab -f docker-compose.yml -f docker-compose.windows.yml --profile windows down --volumes --remove-orphans
}
else {
    Write-Host 'No .env.lab found. Attempting compose down with defaults...'
    docker compose down --volumes --remove-orphans
}

$projectLabel = 'com.docker.compose.project=c2-labs'

$containers = docker ps -a --filter "label=$projectLabel" --format '{{.ID}}'
if ($containers) {
    Write-Host 'Removing leftover containers...'
    $containers | ForEach-Object { docker rm -f $_ | Out-Null }
}

$networks = docker network ls --filter "label=$projectLabel" --format '{{.ID}}'
if ($networks) {
    Write-Host 'Removing leftover networks...'
    $networks | ForEach-Object { docker network rm $_ | Out-Null }
}

$volumes = docker volume ls --filter "label=$projectLabel" --format '{{.Name}}'
if ($volumes) {
    Write-Host 'Removing leftover volumes...'
    $volumes | ForEach-Object { docker volume rm $_ | Out-Null }
}

if ($RemoveAgentImages) {
    $images = docker images --format '{{.Repository}} {{.ID}}' | Where-Object { $_ -match '^c2-labs-(ubuntu-agent|windows-agent)\s' }
    if ($images) {
        Write-Host 'Removing locally built agent images...'
        $imageIds = $images | ForEach-Object { ($_ -split '\s+')[1] } | Select-Object -Unique
        $imageIds | ForEach-Object { docker image rm -f $_ | Out-Null }
    }
}

if (Test-Path '.env.lab') {
    Remove-Item '.env.lab' -Force
    Write-Host 'Removed .env.lab'
}

Write-Host 'Lab environment reverted.'
