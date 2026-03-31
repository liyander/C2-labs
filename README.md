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

Recommended one-command startup from repository root:

```bash
chmod +x start scripts/start-all.sh scripts/activate-beacons.sh scripts/revert-lab.sh
./start
```

One-command startup plus Linux auto-activation:

```bash
./start --linux-launcher "<PASTE_LINUX_LAUNCHER>"
```

**Adversary Emulation Mode (Auto Deploy):**
Automatically sets up an HTTP listener in Empire, generates the payload, and dynamically executes it against the local containers without any UI interaction:

```bash
./start --auto-deploy
```

One-command startup plus Linux and Windows auto-activation:

```bash
./start \
  --linux-launcher "<PASTE_LINUX_LAUNCHER>" \
  --windows-launcher "<PASTE_WINDOWS_LAUNCHER>"
```

Optional target selection during auto-activation:

```bash
./start --linux-launcher "<PASTE_LINUX_LAUNCHER>" --linux-targets ubuntu
./start --linux-launcher "<PASTE_LINUX_LAUNCHER>" --linux-targets linux-victim
./start --linux-launcher "<PASTE_LINUX_LAUNCHER>" --linux-targets both
```

Linux single command start (build + run):

```bash
chmod +x scripts/start-all.sh scripts/revert-lab.sh
./scripts/start-all.sh
```

Linux force clean rebuild while starting:

```bash
./scripts/start-all.sh --rebuild
```

Linux revert/cleanup:

```bash
./scripts/revert-lab.sh
```

Linux revert/cleanup including local images:

```bash
./scripts/revert-lab.sh --remove-images
```

Note for Linux environments:
- Native Linux Docker hosts cannot run Windows containers.
- Run only `empire`, `ubuntu-agent`, and `linux-victim` on Linux.
- Run `windows-agent` and `windows-victim` from a Windows Docker host.

Default behavior in this lab:
- Empire host ports are random by default (`EMPIRE_API_HOST_PORT=0`, `EMPIRE_LISTENER_HOST_PORT=0`).
- A local bridge always exposes `http://127.0.0.1:1337` and forwards to Empire API.
- This prevents UI login failures when a frontend still calls `/token` on port `1337`.

If you want random host ports for Empire, set these in `.env.lab` before start:
- `EMPIRE_API_HOST_PORT=0`
- `EMPIRE_LISTENER_HOST_PORT=0`

Then discover assigned ports:

```bash
docker compose --env-file .env.lab port empire 1337
docker compose --env-file .env.lab port empire 5000
```

Use either:
- Discovered mapped API port for direct access, or
- Stable bridge endpoint `http://127.0.0.1:1337`

Single command start (build + run):

```powershell
./scripts/start-all.ps1
```

Single command start including Windows services:

```powershell
./scripts/start-all.ps1 -IncludeWindows
```

Force clean rebuild while starting:

```powershell
./scripts/start-all.ps1 -Rebuild
```

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
API_PORT=$(docker compose --env-file .env.lab port empire 1337 | sed -E 's/.*:([0-9]+)$/\1/' | head -n1)
curl -fsS "http://127.0.0.1:${API_PORT}/api/v2/meta/version"
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

Activation workflow:
1. Create a Linux-compatible listener and generate a launcher command.
2. Run launcher into Linux containers:

```bash
./scripts/activate-beacons.sh --linux-launcher "<PASTE_LINUX_LAUNCHER>"
```

3. If running on a Windows Docker host, create Windows listener/launcher and run:

```bash
./scripts/activate-beacons.sh \
  --linux-launcher "<PASTE_LINUX_LAUNCHER>" \
  --windows-launcher "<PASTE_WINDOWS_LAUNCHER>"
```

4. Confirm check-ins in Empire agents view.

Important listener host settings for this lab:
- For Ubuntu agent in Docker network, use host `empire` and listener port `1337`.
- For host/WSL testing from outside containers, use `127.0.0.1:1337`.

## 3) Execute Launcher In Agent Containers

You can still execute manually with PowerShell helper script:

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
  - Recreate services after compose changes: `docker compose --env-file .env.lab up -d --build --force-recreate empire empire-api-bridge ubuntu-agent linux-victim`
  - Discover current API mapping: `docker compose --env-file .env.lab port empire 1337`
  - Discover current listener mapping: `docker compose --env-file .env.lab port empire 5000`
  - Verify local reachability using mapped API port and bridge endpoint `http://127.0.0.1:1337`
  - `ERR_CONNECTION_REFUSED` to `localhost:1337/token` means bridge is not running; start `empire-api-bridge`
- If Windows service fails to build/run:
  - Switch Docker Desktop to Windows containers mode
  - Re-run `./scripts/start-lab.ps1 -IncludeWindows`
- If agents are not activating:
  - Ensure listeners were created in Empire before launcher execution
  - Use one-command activation: `./start --linux-launcher "<LAUNCHER>"`
  - Use `./scripts/activate-beacons.sh --linux-launcher "<LAUNCHER>"`
  - Check container logs: `docker compose --env-file .env.lab logs -f ubuntu-agent linux-victim`
- If launcher command has quote issues, wrap it in single quotes in PowerShell invocation where possible.
