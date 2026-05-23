#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PHONE_DIR="$ROOT_DIR/phone"
RELEASES_DIR="$PHONE_DIR/releases"
PUBSPEC_PATH="$PHONE_DIR/pubspec.yaml"
SPLIT_OUT_DIR="$PHONE_DIR/build/app/outputs/flutter-apk"

if [ ! -f "$PUBSPEC_PATH" ]; then
  echo "ERROR: pubspec.yaml not found at $PUBSPEC_PATH"
  exit 1
fi

VERSION_LINE="$(grep -E '^version:' "$PUBSPEC_PATH" | head -n 1 || true)"
if [ -z "$VERSION_LINE" ]; then
  echo "ERROR: Could not extract version from $PUBSPEC_PATH"
  exit 1
fi

APP_VERSION="$(printf '%s' "$VERSION_LINE" | sed -E 's/^version:[[:space:]]*([^+[:space:]]+).*/\1/')"
if [ -z "$APP_VERSION" ]; then
  echo "ERROR: Parsed empty version from $PUBSPEC_PATH"
  exit 1
fi

cd "$PHONE_DIR"

echo "Building split release APKs for ARM targets..."
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64

ARM64_SRC="$SPLIT_OUT_DIR/app-arm64-v8a-release.apk"
ARMV7_SRC="$SPLIT_OUT_DIR/app-armeabi-v7a-release.apk"

if [ ! -f "$ARM64_SRC" ] || [ ! -f "$ARMV7_SRC" ]; then
  echo "ERROR: Expected split APKs were not generated."
  echo "Missing files checked:"
  echo "  $ARM64_SRC"
  echo "  $ARMV7_SRC"
  exit 1
fi

mkdir -p "$RELEASES_DIR"

ARM64_DST="$RELEASES_DIR/avodah-viewer-v${APP_VERSION}-arm64.apk"
ARMV7_DST="$RELEASES_DIR/avodah-viewer-v${APP_VERSION}-armv7.apk"

cp "$ARM64_SRC" "$ARM64_DST"
cp "$ARMV7_SRC" "$ARMV7_DST"

echo "Release artifacts:"
ls -lh "$ARM64_DST" "$ARMV7_DST"
