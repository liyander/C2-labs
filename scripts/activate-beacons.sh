#!/usr/bin/env bash
set -euo pipefail

LINUX_LAUNCHER=""
WINDOWS_LAUNCHER=""
LINUX_TARGETS="both"
WINDOWS_TARGETS="both"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/activate-beacons.sh --linux-launcher "<launcher>" [options]

Options:
  --linux-launcher <cmd>       Required. Launcher command from Empire for Linux beacon.
  --windows-launcher <cmd>     Optional. Launcher command from Empire for Windows beacon.
  --linux-targets <set>        ubuntu|linux-victim|both (default: both)
  --windows-targets <set>      windows|windows-victim|both (default: both)

Notes:
  1) Listeners must be created in Empire first.
  2) On native Linux Docker hosts, Windows containers are not supported.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --linux-launcher)
      LINUX_LAUNCHER="${2:-}"
      shift 2
      ;;
    --windows-launcher)
      WINDOWS_LAUNCHER="${2:-}"
      shift 2
      ;;
    --linux-targets)
      LINUX_TARGETS="${2:-both}"
      shift 2
      ;;
    --windows-targets)
      WINDOWS_TARGETS="${2:-both}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$LINUX_LAUNCHER" ]]; then
  echo "--linux-launcher is required" >&2
  usage
  exit 1
fi

if [[ ! -f .env.lab ]]; then
  echo "Missing .env.lab. Run ./scripts/start-all.sh first." >&2
  exit 1
fi

if ! docker compose --env-file .env.lab ps empire >/dev/null 2>&1; then
  echo "Empire service not found. Start the lab first." >&2
  exit 1
fi

run_launcher() {
  local service="$1"
  local launcher="$2"

  local encoded
  encoded="$(printf '%s' "$launcher" | iconv -f UTF-8 -t UTF-16LE | base64 -w 0)"
  echo "Running launcher in ${service}..."
  docker compose --env-file .env.lab exec -T "$service" pwsh -NoLogo -NoProfile -NonInteractive -EncodedCommand "$encoded"
}

case "$LINUX_TARGETS" in
  ubuntu)
    run_launcher ubuntu-agent "$LINUX_LAUNCHER"
    ;;
  linux-victim)
    run_launcher linux-victim "$LINUX_LAUNCHER"
    ;;
  both)
    run_launcher ubuntu-agent "$LINUX_LAUNCHER"
    run_launcher linux-victim "$LINUX_LAUNCHER"
    ;;
  *)
    echo "Invalid --linux-targets value: $LINUX_TARGETS" >&2
    exit 1
    ;;
esac

if [[ -n "$WINDOWS_LAUNCHER" ]]; then
  os_type="$(docker info --format '{{.OSType}}' 2>/dev/null || true)"
  if [[ "$os_type" != "windows" ]]; then
    echo "Skipping Windows activation: Docker engine OSType is '$os_type' (not windows)."
  else
    base_args=(--env-file .env.lab -f docker-compose.yml -f docker-compose.windows.yml --profile windows)

    run_windows_launcher() {
      local service="$1"
      local launcher="$2"
      local encoded
      encoded="$(printf '%s' "$launcher" | iconv -f UTF-8 -t UTF-16LE | base64 -w 0)"
      echo "Running launcher in ${service}..."
      docker compose "${base_args[@]}" exec -T "$service" pwsh -NoLogo -NoProfile -NonInteractive -EncodedCommand "$encoded"
    }

    case "$WINDOWS_TARGETS" in
      windows)
        run_windows_launcher windows-agent "$WINDOWS_LAUNCHER"
        ;;
      windows-victim)
        run_windows_launcher windows-victim "$WINDOWS_LAUNCHER"
        ;;
      both)
        run_windows_launcher windows-agent "$WINDOWS_LAUNCHER"
        run_windows_launcher windows-victim "$WINDOWS_LAUNCHER"
        ;;
      *)
        echo "Invalid --windows-targets value: $WINDOWS_TARGETS" >&2
        exit 1
        ;;
    esac
  fi
fi

echo "Activation commands sent. Verify check-ins in Empire agents view."
