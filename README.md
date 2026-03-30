# Empire PowerShell C2 Lab (Docker)

This lab provides:
- Empire server in Docker (buildable as local image)
- Ubuntu agent container in Docker
- Linux victim container in Docker
- Windows agent container in Docker (Windows containers mode)
- Windows victim container in Docker (Windows containers mode)
- Revert script to tear down and clean all lab resources

## Files

- `docker-compose.yml` : Empire + Ubuntu agent
- `docker-compose.windows.yml` : Windows agent + Windows victim profile
- `scripts/start-lab.ps1` : starts lab, creates `.env.lab`
- `scripts/run-agent-launcher.ps1` : runs Empire launcher command inside target agent container
- `scripts/revert-lab.ps1` : reverts lab and removes created resources

## Prerequisites

- Docker Desktop
- PowerShell 7 or Windows PowerShell

## Build Images

Build Empire image directly:

```bash
docker build -t c2-labs-empire:latest -f docker/empire/Dockerfile docker/empire
```

Build Empire image from repository root:

```bash
docker build -t empire-c2 .
```

Build Ubuntu agent image directly:

```bash
docker build -t c2-labs-ubuntu-agent:latest -f docker/ubuntu-agent/Dockerfile docker/ubuntu-agent
```

Build Linux victim image directly:

```bash
docker build -t c2-labs-linux-victim:latest -f docker/linux-victim/Dockerfile docker/linux-victim
```

Build with Compose services:

```bash
docker compose --env-file .env.lab build empire ubuntu-agent linux-victim
```

## 1) Start Lab

From workspace root:

```powershell
./scripts/start-lab.ps1
```

Equivalent Docker Compose command:

```powershell
docker compose --env-file .env.lab up -d --build empire ubuntu-agent linux-victim
```

This starts:
- Empire server on `http://localhost:1337`
- Ubuntu agent container
- Linux victim container

Verify C2 is exposed:

```bash
docker compose --env-file .env.lab ps
curl -fsS http://127.0.0.1:1337/api/v2/meta/version
```

To also start Windows agent container:

```powershell
./scripts/start-lab.ps1 -IncludeWindows
```

Equivalent Docker Compose command:

```powershell
docker compose --env-file .env.lab -f docker-compose.yml -f docker-compose.windows.yml --profile windows up -d --build windows-agent windows-victim
```

Build Windows profile services:

```powershell
docker compose --env-file .env.lab -f docker-compose.yml -f docker-compose.windows.yml --profile windows build windows-agent windows-victim
```

Note:
- `-IncludeWindows` requires Docker Desktop in Windows containers mode.
- You may need to start Linux stack first, then switch modes for Windows stack if your Docker setup cannot run both simultaneously.

## 2) Prepare Listener and Launchers in Empire

Use Empire UI/API/CLI to create listeners and generate launchers for:
- Ubuntu target (PowerShell launcher)
- Linux victim (PowerShell launcher)
- Windows target (PowerShell launcher)
- Windows victim (PowerShell launcher)

Example launcher output from Empire usually looks like a single PowerShell command.

Important listener host settings for this lab:
- For Ubuntu agent in Docker network, use host `empire` and listener port `1337`.
- For host/WSL testing from outside containers, use `127.0.0.1:1337`.

## 3) Execute Launcher In Agent Containers

Run launcher in Ubuntu agent:

```powershell
./scripts/run-agent-launcher.ps1 -Target ubuntu -Launcher "<PASTE_EMPIRE_LAUNCHER_COMMAND>"
```

Run launcher in Windows agent:

```powershell
./scripts/run-agent-launcher.ps1 -Target windows -Launcher "<PASTE_EMPIRE_LAUNCHER_COMMAND>"
```

Run launcher in Linux victim:

```powershell
./scripts/run-agent-launcher.ps1 -Target linux-victim -Launcher "<PASTE_EMPIRE_LAUNCHER_COMMAND>"
```

Run launcher in Windows victim:

```powershell
./scripts/run-agent-launcher.ps1 -Target windows-victim -Launcher "<PASTE_EMPIRE_LAUNCHER_COMMAND>"
```

## 4) Perform Operations

After both agents check in to Empire, perform your operations from Empire modules/tasks.

## 5) Revert Lab Changes

Stop and remove containers, networks, volumes, and local env file:

```powershell
./scripts/revert-lab.ps1
```

Also remove locally built agent images:

```powershell
./scripts/revert-lab.ps1 -RemoveAgentImages
```

## Troubleshooting

- Compose service names are `empire`, `ubuntu-agent`, and `windows-agent`.
- Compose service names are `empire`, `ubuntu-agent`, `linux-victim`, `windows-agent`, and `windows-victim`.
- `empire-c2` is the container name, not the Compose service name.
- Correct build examples:
  - `docker compose --env-file .env.lab build empire`
  - `docker compose --env-file .env.lab build ubuntu-agent`
  - `docker compose --env-file .env.lab build linux-victim`
  - `docker compose --env-file .env.lab -f docker-compose.yml -f docker-compose.windows.yml --profile windows build windows-agent windows-victim`
- `docker-compose build empire-c2 .` fails because:
  - `empire-c2` is not a service name
  - trailing `.` is treated as another service token

- If Empire image build fails, verify base image availability:
  - `docker pull bcsecurity/empire:latest`
- If C2 is not exposed:
  - Recreate services after compose changes: `docker compose --env-file .env.lab up -d --build --force-recreate empire ubuntu-agent`
  - Confirm published ports show `0.0.0.0:1337->1337` in `docker compose --env-file .env.lab ps`
  - Verify local reachability: `curl -fsS http://127.0.0.1:1337/api/v2/meta/version`
- If Windows service fails to build/run:
  - Switch Docker Desktop to Windows containers mode
  - Re-run `./scripts/start-lab.ps1 -IncludeWindows`
- If launcher command has quote issues, wrap it in single quotes in PowerShell invocation where possible.
