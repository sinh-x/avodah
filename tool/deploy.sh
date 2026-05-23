#!/usr/bin/env bash
# Build split release APKs and install on connected Android device(s).
# Usage: ./tool/deploy.sh [device-name]
#   device-name  Optional substring to match against adb device serial/model.
#                If omitted, installs on all connected devices.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PHONE_DIR="$ROOT_DIR/phone"
DEVICE_FILTER="${1:-}"

cd "$ROOT_DIR"

# --- Build ---
echo "Building split release APKs..."
bash "$ROOT_DIR/tool/build-apk.sh"

# --- Detect devices ---
DEVICES=$(adb devices | tail -n +2 | grep -w 'device' | awk '{print $1}')

if [ -z "$DEVICES" ]; then
  echo "ERROR: No connected devices found."
  exit 1
fi

# --- Install ---
INSTALLED=0
for SERIAL in $DEVICES; do
  if [ -n "$DEVICE_FILTER" ]; then
    # Match filter against serial or device model
    MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null || echo "")
    if [[ "$SERIAL" != *"$DEVICE_FILTER"* && "$MODEL" != *"$DEVICE_FILTER"* ]]; then
      continue
    fi
  fi

  ABI=$(adb -s "$SERIAL" shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r')
  case "$ABI" in
    arm64-v8a)
      APK_PATH="$PHONE_DIR/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
      ABI_LABEL="arm64"
      ;;
    armeabi-v7a)
      APK_PATH="$PHONE_DIR/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
      ABI_LABEL="armv7"
      ;;
    *)
      echo "Skipping $SERIAL: unsupported ABI '$ABI'"
      continue
      ;;
  esac

  if [ ! -f "$APK_PATH" ]; then
    echo "ERROR: Expected APK missing for $SERIAL ($ABI_LABEL): $APK_PATH"
    exit 1
  fi

  echo "Installing $ABI_LABEL APK on $SERIAL (ABI: $ABI)..."
  adb -s "$SERIAL" install -r "$APK_PATH"
  INSTALLED=$((INSTALLED + 1))
done

if [ "$INSTALLED" -eq 0 ]; then
  echo "ERROR: No device matched filter '$DEVICE_FILTER'."
  echo "Connected devices:"
  adb devices -l | tail -n +2
  exit 1
fi

echo "Done. Installed on $INSTALLED device(s)."
