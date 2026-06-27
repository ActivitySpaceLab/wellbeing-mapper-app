#!/usr/bin/env bash

# Build and install Android APK to a USB-connected phone.
# Handles common ADB unauthorized-state recovery with clear prompts.
#
# Usage:
#   ./scripts/deploy-android-phone.sh [production|beta] [arm64-v8a|armeabi-v7a|x86_64] [--serial DEVICE_SERIAL] [--reset-keys]
#
# Examples:
#   ./scripts/deploy-android-phone.sh
#   ./scripts/deploy-android-phone.sh production arm64-v8a
#   ./scripts/deploy-android-phone.sh beta armeabi-v7a
#   ./scripts/deploy-android-phone.sh production arm64-v8a --serial RZCW90B03FV
#   ./scripts/deploy-android-phone.sh production arm64-v8a --reset-keys

set -euo pipefail

FLAVOR="${1:-production}"
ABI="${2:-arm64-v8a}"
TARGET_SERIAL=""
RESET_KEYS=0

shift $(( $# > 0 ? 1 : 0 )) || true
shift $(( $# > 0 ? 1 : 0 )) || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial)
      if [[ $# -lt 2 ]]; then
        echo "Error: --serial requires a value"
        exit 1
      fi
      TARGET_SERIAL="$2"
      shift 2
      ;;
    --reset-keys)
      RESET_KEYS=1
      shift
      ;;
    *)
      echo "Error: unknown option '$1'"
      echo "Usage: $0 [production|beta] [arm64-v8a|armeabi-v7a|x86_64] [--serial DEVICE_SERIAL] [--reset-keys]"
      exit 1
      ;;
  esac
done

if [[ "$FLAVOR" != "production" && "$FLAVOR" != "beta" ]]; then
  echo "Error: flavor must be 'production' or 'beta'"
  echo "Usage: $0 [production|beta] [arm64-v8a|armeabi-v7a|x86_64] [--serial DEVICE_SERIAL] [--reset-keys]"
  exit 1
fi

if [[ "$ABI" != "arm64-v8a" && "$ABI" != "armeabi-v7a" && "$ABI" != "x86_64" ]]; then
  echo "Error: ABI must be one of: arm64-v8a, armeabi-v7a, x86_64"
  echo "Usage: $0 [production|beta] [arm64-v8a|armeabi-v7a|x86_64] [--serial DEVICE_SERIAL] [--reset-keys]"
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' not found in PATH"
    exit 1
  fi
}

get_first_device_line() {
  if [[ -n "$TARGET_SERIAL" ]]; then
    adb devices -l | awk -v serial="$TARGET_SERIAL" 'NR>1 && $1==serial {print; exit}'
  else
    adb devices -l | awk 'NR>1 && NF>0 {print; exit}'
  fi
}

get_device_status() {
  local line
  line="$(get_first_device_line)"
  if [[ -z "$line" ]]; then
    echo "none"
    return
  fi
  echo "$line" | awk '{print $2}'
}

get_device_serial() {
  local line
  line="$(get_first_device_line)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  echo "$line" | awk '{print $1}'
}

print_unauthorized_help() {
  echo ""
  echo "ADB device is unauthorized. On your phone, do this now:"
  echo "1) Keep phone unlocked"
  echo "2) USB mode: File transfer"
  echo "3) Accept the 'Allow USB debugging' fingerprint prompt"
  echo "4) If no prompt appears: Developer options -> Revoke USB debugging authorizations"
  echo ""
}

recover_adb() {
  echo "Restarting ADB server..."
  adb kill-server || true
  adb start-server >/dev/null
}

wait_for_authorized_device() {
  local attempts=0
  local max_attempts=5

  while (( attempts < max_attempts )); do
    local status
    status="$(get_device_status)"

    if [[ "$status" == "device" ]]; then
      return 0
    fi

    if [[ "$status" == "none" ]]; then
      echo "No Android device detected. Connect phone via USB and keep it unlocked."
    elif [[ "$status" == "unauthorized" ]]; then
      print_unauthorized_help
    else
      echo "Current device status: $status"
    fi

    attempts=$((attempts + 1))
    read -r -p "Press Enter after fixing on phone (attempt $attempts/$max_attempts)... " _
    recover_adb
  done

  return 1
}

install_apk() {
  local serial="$1"
  local apk_path="$2"

  echo "Installing APK on device $serial"
  adb -s "$serial" install --no-streaming -r -g "$apk_path"
}

main() {
  require_cmd adb
  require_cmd fvm

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_root
  project_root="$(cd "$script_dir/.." && pwd)"
  cd "$project_root"

  echo "Checking ADB device status..."

  if [[ "$RESET_KEYS" -eq 1 ]]; then
    echo "Removing local ADB keys for clean re-auth..."
    rm -f "$HOME/.android/adbkey" "$HOME/.android/adbkey.pub"
  fi

  recover_adb

  if ! wait_for_authorized_device; then
    echo ""
    echo "Could not get an authorized device after multiple attempts."
    echo "Manual one-time reset on Mac (safe) if needed:"
    echo "  rm -f ~/.android/adbkey ~/.android/adbkey.pub"
    echo "Then run this script again and accept the new fingerprint prompt on phone."
    exit 2
  fi

  local serial
  serial="$(get_device_serial)"
  if [[ -n "$TARGET_SERIAL" && "$serial" != "$TARGET_SERIAL" ]]; then
    echo "Requested serial '$TARGET_SERIAL' is not currently available."
    exit 1
  fi
  echo "Authorized device detected: $serial"

  echo "Building $FLAVOR APKs (split per ABI)..."
  fvm flutter build apk --split-per-abi --flavor "$FLAVOR"

  local apk_path="build/app/outputs/flutter-apk/app-$ABI-$FLAVOR-release.apk"
  if [[ ! -f "$apk_path" ]]; then
    echo "Expected APK not found: $apk_path"
    exit 1
  fi

  install_apk "$serial" "$apk_path"
  echo ""
  echo "Success: installed $apk_path on $serial"
}

main "$@"
