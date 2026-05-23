#!/usr/bin/env bash

apk_output_dir() {
  local root_dir="$1"
  printf '%s/phone/build/app/outputs/flutter-apk' "$root_dir"
}

apk_path_for_abi() {
  local root_dir="$1"
  local abi="$2"
  local out_dir
  out_dir="$(apk_output_dir "$root_dir")"

  case "$abi" in
    arm64-v8a)
      printf '%s/app-arm64-v8a-release.apk' "$out_dir"
      ;;
    armeabi-v7a)
      printf '%s/app-armeabi-v7a-release.apk' "$out_dir"
      ;;
    *)
      return 1
      ;;
  esac
}

apk_label_for_abi() {
  local abi="$1"
  case "$abi" in
    arm64-v8a)
      printf 'arm64'
      ;;
    armeabi-v7a)
      printf 'armv7'
      ;;
    *)
      return 1
      ;;
  esac
}
