#!/usr/bin/env bash
# Build split release APKs and install on connected Android device(s).
# Usage: ./tool/deploy.sh [device-name]
#   device-name  Optional substring to match against adb device serial/model.
#                If omitted, installs on all connected devices.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PHONE_DIR="$ROOT_DIR/phone"
DEVICE_FILTER="${1:-}"

# Shared ABI -> APK output path mapping.
# shellcheck source=tool/apk-paths.sh
source "$ROOT_DIR/tool/apk-paths.sh"

cd "$ROOT_DIR"

# --- Build ---
if [ ! -f "$ROOT_DIR/tool/build-apk.sh" ]; then
  echo "ERROR: Required build script not found: $ROOT_DIR/tool/build-apk.sh"
  exit 1
fi

echo "Building split release APKs..."
bash "$ROOT_DIR/tool/build-apk.sh"

# --- Detect devices ---
DEVICES=$(adb devices | tail -n +2 | grep -w 'device' | awk '{print $1}')

if [ -z "$DEVICES" ]; then
  echo "ERROR: No connected devices found."
  exit 1
fi

# --- Collect install targets and required APKs ---
SUPPORTED_MATCHED=0
FILTER_MATCHED=0
declare -a TARGET_SERIALS=()
declare -A DEVICE_ABI=()
declare -A REQUIRED_ABI=()

for SERIAL in $DEVICES; do
  if [ -n "$DEVICE_FILTER" ]; then
    # Match filter against serial or device model
    MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null || echo "")
    if [[ "$SERIAL" != *"$DEVICE_FILTER"* && "$MODEL" != *"$DEVICE_FILTER"* ]]; then
      continue
    fi
    FILTER_MATCHED=1
  fi

  ABI=$(adb -s "$SERIAL" shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r')
  if ! apk_path_for_abi "$ROOT_DIR" "$ABI" >/dev/null; then
    echo "Skipping $SERIAL: unsupported ABI '$ABI'"
    continue
  fi

  TARGET_SERIALS+=("$SERIAL")
  DEVICE_ABI["$SERIAL"]="$ABI"
  REQUIRED_ABI["$ABI"]=1
  SUPPORTED_MATCHED=1
done

if [ -n "$DEVICE_FILTER" ] && [ "$FILTER_MATCHED" -eq 0 ]; then
  echo "ERROR: No connected devices matched filter '$DEVICE_FILTER'."
  echo "Connected devices:"
  adb devices -l | tail -n +2
  exit 1
fi

if [ "$SUPPORTED_MATCHED" -eq 0 ]; then
  if [ -n "$DEVICE_FILTER" ]; then
    echo "ERROR: Devices matched filter '$DEVICE_FILTER', but all had unsupported ABIs."
  else
    echo "ERROR: Connected devices found, but all had unsupported ABIs."
  fi
  echo "Connected devices:"
  adb devices -l | tail -n +2
  exit 1
fi

# Validate all APK paths before installing on any device.
for ABI in "${!REQUIRED_ABI[@]}"; do
  APK_PATH="$(apk_path_for_abi "$ROOT_DIR" "$ABI")"
  ABI_LABEL="$(apk_label_for_abi "$ABI")"
  if [ ! -f "$APK_PATH" ]; then
    echo "ERROR: Expected APK missing for ABI '$ABI_LABEL': $APK_PATH"
    exit 1
  fi
done

# --- Install ---
INSTALLED=0
for SERIAL in "${TARGET_SERIALS[@]}"; do
  ABI="${DEVICE_ABI[$SERIAL]}"
  APK_PATH="$(apk_path_for_abi "$ROOT_DIR" "$ABI")"
  ABI_LABEL="$(apk_label_for_abi "$ABI")"

  echo "Installing $ABI_LABEL APK on $SERIAL (ABI: $ABI)..."
  adb -s "$SERIAL" install -r "$APK_PATH"
  INSTALLED=$((INSTALLED + 1))
done

if [ "$INSTALLED" -eq 0 ]; then
  echo "ERROR: No supported devices were selected for install."
  exit 1
fi

echo "Done. Installed on $INSTALLED device(s)."
