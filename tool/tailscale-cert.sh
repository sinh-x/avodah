#!/usr/bin/env bash
# Generates or renews Tailscale TLS certs for the Avodah sync server.
#
# Usage:
#   ./tool/tailscale-cert.sh [domain]
#
# Writes certs to ~/.config/avodah/ (or $AVODAH_CONFIG).
# After running, restart the sync server:
#   docker compose restart avodah-sync
set -euo pipefail

DOMAIN="${1:-drgnfly.tail10c2c6.ts.net}"

# Resolve real user home when run via sudo
if [ -n "${SUDO_USER:-}" ]; then
  REAL_HOME=$(eval echo "~$SUDO_USER")
else
  REAL_HOME="$HOME"
fi

CONFIG_DIR="${AVODAH_CONFIG:-$REAL_HOME/.config/avodah}"

mkdir -p "$CONFIG_DIR"

echo "Generating/renewing Tailscale cert for $DOMAIN..."
echo "Output dir: $CONFIG_DIR"

tailscale cert \
  --cert-file "$CONFIG_DIR/$DOMAIN.crt" \
  --key-file  "$CONFIG_DIR/$DOMAIN.key" \
  "$DOMAIN"

# Make readable by the non-root user running the sync server
chown "${SUDO_USER:-$(whoami)}" "$CONFIG_DIR/$DOMAIN.crt" "$CONFIG_DIR/$DOMAIN.key"
chmod 644 "$CONFIG_DIR/$DOMAIN.crt"
chmod 600 "$CONFIG_DIR/$DOMAIN.key"

echo "Cert: $CONFIG_DIR/$DOMAIN.crt"
echo "Key:  $CONFIG_DIR/$DOMAIN.key"
echo ""
echo "Restart sync server to apply:"
echo "  docker compose restart avodah-sync"
