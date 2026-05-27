#!/usr/bin/env bash
# driver.sh — deploy a plugin from this repo to noctalia and verify it loads.
# Usage: ./driver.sh <plugin-id>
# Example: ./driver.sh garra-kbd-layout
set -euo pipefail

PLUGIN_ID="${1:-}"
PLUGIN_SRC_DIR="$(cd "$(dirname "$0")/../../.." && pwd)/${PLUGIN_ID}"
PLUGIN_DEST_DIR="$HOME/.config/noctalia/plugins/${PLUGIN_ID}"
PLUGINS_JSON="$HOME/.config/noctalia/plugins.json"
LOG_FILE="/tmp/noctalia-restart.log"
SCREENSHOT_DIR="$HOME/Imágenes/Screenshots"

usage() {
  echo "Usage: $0 <plugin-id>" >&2
  echo "  plugin-id must be a directory at the repo root (e.g. garra-kbd-layout)" >&2
  exit 1
}

[[ -z "$PLUGIN_ID" ]] && usage
[[ ! -d "$PLUGIN_SRC_DIR" ]] && { echo "ERROR: $PLUGIN_SRC_DIR not found" >&2; exit 1; }

echo "==> Deploying $PLUGIN_ID..."
cp -r "$PLUGIN_SRC_DIR" "$HOME/.config/noctalia/plugins/"

echo "==> Enabling in plugins.json..."
TMP=$(mktemp)
jq --arg id "$PLUGIN_ID" \
  '.states[$id] = (.states[$id] // {}) | .states[$id].enabled = true' \
  "$PLUGINS_JSON" > "$TMP" && mv "$TMP" "$PLUGINS_JSON"

echo "==> Restarting noctalia-shell..."
pkill -f "qs -c noctalia-shell" 2>/dev/null || true
sleep 1
setsid qs -c noctalia-shell >"$LOG_FILE" 2>&1 </dev/null &
echo "    PID: $!"

echo "==> Waiting for shell to load (5s)..."
sleep 5

echo "==> Checking logs for plugin..."
if grep -q "Plugin loaded: ${PLUGIN_ID}" "$LOG_FILE"; then
  echo "    OK: plugin loaded"
else
  echo "    WARN: plugin load line not found — check $LOG_FILE"
  grep -i "error\|warn\|${PLUGIN_ID}" "$LOG_FILE" | head -10 || true
fi

echo "==> Taking screenshot..."
niri msg action screenshot-screen
sleep 1
LATEST=$(ls -t "$SCREENSHOT_DIR"/*.png 2>/dev/null | head -1)
echo "    Screenshot: $LATEST"

echo "==> Done. Logs: $LOG_FILE"
