#!/bin/sh
set -eu
umask 077
exec /app/sync_server "$@"
