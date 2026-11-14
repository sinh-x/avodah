#!/bin/sh
# Public upstream inputs pinned to checked SHA-256, not mutable latest URLs.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT HUP INT TERM
curl --fail --location --max-time 60 -o "$stage/sqlite3.wasm" https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm
curl --fail --location --max-time 60 -o "$stage/drift_worker.js" https://github.com/simolus3/drift/releases/download/drift-2.31.0/drift_worker.js
(cd "$stage" && printf '%s\n' \
  '922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117  sqlite3.wasm' \
  'f0a9b87085f732fd7b6ee7eb34d3858c556f05d221eb1febfc443649cd365752  drift_worker.js' | sha256sum --check)
cp "$stage/sqlite3.wasm" "$root/phone/web/sqlite3.wasm"
cp "$stage/drift_worker.js" "$root/phone/web/drift_worker.js"
