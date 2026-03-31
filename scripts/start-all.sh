#!/usr/bin/env bash
set -euo pipefail

INCLUDE_WINDOWS=0
REBUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-windows)
      INCLUDE_WINDOWS=1
      shift
      ;;
    --rebuild)
      REBUILD=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: ./scripts/start-all.sh [--include-windows] [--rebuild]" >&2
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Missing required command: docker" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env.lab ]]; then
  ADMIN_USER="empireadmin"
  ADMIN_PASS="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 || true)"
  if [[ -z "$ADMIN_PASS" ]]; then
    ADMIN_PASS="ChangeThisNow123"
  fi

  cat > .env.lab <<EOF
EMPIRE_ADMIN_USERNAME=${ADMIN_USER}
EMPIRE_ADMIN_PASSWORD=${ADMIN_PASS}
EMPIRE_API_HOST_PORT=1337
EMPIRE_LISTENER_HOST_PORT=5000
UBUNTU_AGENT_LAUNCHER=
WINDOWS_AGENT_LAUNCHER=
LINUX_VICTIM_LAUNCHER=
WINDOWS_VICTIM_LAUNCHER=
EOF

  echo "Created .env.lab with randomized Empire admin password."
fi

NO_CACHE_ARGS=()
if [[ "$REBUILD" -eq 1 ]]; then
  NO_CACHE_ARGS=(--no-cache)
fi

echo "Building Linux-side images..."
docker build "${NO_CACHE_ARGS[@]}" -t c2-labs-empire:latest -t empire-c2 -f Dockerfile .
docker build "${NO_CACHE_ARGS[@]}" -t c2-labs-ubuntu-agent:latest -f docker/ubuntu-agent/Dockerfile docker/ubuntu-agent
docker build "${NO_CACHE_ARGS[@]}" -t c2-labs-linux-victim:latest -f docker/linux-victim/Dockerfile docker/linux-victim

echo "Starting Empire + Ubuntu agent + Linux victim..."
docker compose --env-file .env.lab up -d empire ubuntu-agent linux-victim

API_BIND="$(docker compose --env-file .env.lab port empire 1337 | head -n 1 || true)"
LISTENER_BIND="$(docker compose --env-file .env.lab port empire 5000 | head -n 1 || true)"

API_PORT="${API_BIND##*:}"
LISTENER_PORT="${LISTENER_BIND##*:}"

if [[ "$INCLUDE_WINDOWS" -eq 1 ]]; then
  echo "Windows containers are not supported on a native Linux Docker host."
  echo "Run Windows services from a Windows Docker environment instead."
  exit 2
fi

echo
echo "Lab is up."
if [[ -n "$API_PORT" ]]; then
  echo "Empire API: http://127.0.0.1:${API_PORT}"
else
  echo "Empire API port mapping not detected. Check: docker compose --env-file .env.lab ps"
fi
if [[ -n "$LISTENER_PORT" ]]; then
  echo "Empire listener port: ${LISTENER_PORT}"
fi
echo "Use scripts/run-agent-launcher.ps1 for beacon launchers if running from PowerShell."
