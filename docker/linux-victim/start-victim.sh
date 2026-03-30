#!/usr/bin/env sh
set -eu

if [ -n "${BEACON_LAUNCHER:-}" ]; then
  echo "[linux-victim] Executing beacon launcher from environment"
  pwsh -NoLogo -NoProfile -NonInteractive -Command "$BEACON_LAUNCHER"
else
  echo "[linux-victim] No beacon launcher set. Waiting for operator command."
fi

exec tail -f /dev/null
