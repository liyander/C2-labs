#!/usr/bin/env bash
set -euo pipefail

REMOVE_IMAGES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-images)
      REMOVE_IMAGES=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: ./scripts/revert-lab.sh [--remove-images]" >&2
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env.lab ]]; then
  echo "Stopping Linux lab services..."
  docker compose --env-file .env.lab down --volumes --remove-orphans || true
else
  echo "No .env.lab found. Attempting compose down with defaults..."
  docker compose down --volumes --remove-orphans || true
fi

PROJECT_LABEL="com.docker.compose.project=c2-labs"

CONTAINERS="$(docker ps -a --filter "label=${PROJECT_LABEL}" --format '{{.ID}}' || true)"
if [[ -n "$CONTAINERS" ]]; then
  echo "Removing leftover containers..."
  while IFS= read -r id; do
    [[ -n "$id" ]] && docker rm -f "$id" >/dev/null || true
  done <<< "$CONTAINERS"
fi

NETWORKS="$(docker network ls --filter "label=${PROJECT_LABEL}" --format '{{.ID}}' || true)"
if [[ -n "$NETWORKS" ]]; then
  echo "Removing leftover networks..."
  while IFS= read -r id; do
    [[ -n "$id" ]] && docker network rm "$id" >/dev/null || true
  done <<< "$NETWORKS"
fi

VOLUMES="$(docker volume ls --filter "label=${PROJECT_LABEL}" --format '{{.Name}}' || true)"
if [[ -n "$VOLUMES" ]]; then
  echo "Removing leftover volumes..."
  while IFS= read -r name; do
    [[ -n "$name" ]] && docker volume rm "$name" >/dev/null || true
  done <<< "$VOLUMES"
fi

if [[ "$REMOVE_IMAGES" -eq 1 ]]; then
  echo "Removing locally built lab images..."
  docker images --format '{{.Repository}} {{.ID}}' \
    | awk '/^c2-labs-(empire|ubuntu-agent|linux-victim|windows-agent|windows-victim) / {print $2}' \
    | sort -u \
    | while IFS= read -r img; do
        [[ -n "$img" ]] && docker image rm -f "$img" >/dev/null || true
      done
fi

if [[ -f .env.lab ]]; then
  rm -f .env.lab
  echo "Removed .env.lab"
fi

echo "Lab environment reverted."
