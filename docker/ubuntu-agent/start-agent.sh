#!/usr/bin/env sh
set -eu

if [ -n "${AGENT_LAUNCHER:-}" ]; then
  echo "[ubuntu-agent] Executing launcher from environment"
  pwsh -NoLogo -NoProfile -NonInteractive -Command "$AGENT_LAUNCHER"
else
  echo "[ubuntu-agent] No launcher set. Container will stay alive for manual operations."
fi

# Keep container alive for operator-driven commands.
exec tail -f /dev/null
