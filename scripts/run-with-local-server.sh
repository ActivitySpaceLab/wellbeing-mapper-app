#!/usr/bin/env bash
# Run the Flutter app pointed at a locally-running wellbeing-mapper-server.
#
# Prereq: in another terminal, start the server:
#     cd ../wellbeing-mapper-server && npm run dev
#
# Usage:
#     scripts/run-with-local-server.sh [extra flutter run args]
#
# Env overrides:
#     SERVER_HOST  Hostname/IP the device should reach the server on.
#                  Defaults to 10.0.2.2 for Android emulator, localhost otherwise.
#     SERVER_PORT  Defaults to 3000.
#     APP_FLAVOR   Defaults to production (matches build-flavors.sh).

set -euo pipefail

cd "$(dirname "$0")/.."

PORT="${SERVER_PORT:-3000}"
FLAVOR="${APP_FLAVOR:-production}"

# Pick a sensible default host based on the active device.
if [[ -z "${SERVER_HOST:-}" ]]; then
  if fvm flutter devices 2>/dev/null | grep -qiE 'android.*emulator'; then
    SERVER_HOST="10.0.2.2"   # Android emulator loopback to host.
  else
    SERVER_HOST="localhost"
  fi
fi

BASE_URL="http://${SERVER_HOST}:${PORT}/api/v1"

echo "[run-with-local-server] SERVER_BASE_URL=${BASE_URL}"
echo "[run-with-local-server] APP_FLAVOR=${FLAVOR}"

exec fvm flutter run \
  --dart-define=SERVER_BASE_URL="${BASE_URL}" \
  --dart-define=APP_FLAVOR="${FLAVOR}" \
  "$@"
