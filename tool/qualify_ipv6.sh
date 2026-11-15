#!/bin/sh
# Disposable IPv6-only namespace. No production mounts, host ports or sysctls.
set -eu
sync_image=${1:?explicit test sync image required}
web_image=${2:?explicit test web image required}
case "$sync_image:$web_image" in avodah-avo121-test-*:avodah-avo121-test-*) ;; *) exit 64;; esac
sync=''; web=''
cleanup() {
  [ -z "$web" ] || docker rm -f -v "$web" >/dev/null 2>&1 || true
  [ -z "$sync" ] || docker rm -f -v "$sync" >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM
uid=$(id -u); gid=$(id -g)
sync=$(docker run -d --name "avo121-ipv6-sync-$$" --network none \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 --cap-drop ALL --security-opt no-new-privileges \
  --user "$uid:$gid" --tmpfs "/data:uid=$uid,gid=$gid,mode=0700" \
  --tmpfs "/config:uid=$uid,gid=$gid,mode=0700" \
  -e XDG_STATE_HOME=/data/state -e HOME=/tmp -e SYNC_HOST=::1 -e SYNC_PORT=19849 \
  -e JIRA_ENABLED=false "$sync_image")
web=$(docker run -d --name "avo121-ipv6-web-$$" --network "container:$sync" \
  --cap-drop ALL --cap-add NET_BIND_SERVICE --security-opt no-new-privileges \
  --user "$uid:$gid" -e XDG_CONFIG_HOME=/tmp/config -e XDG_DATA_HOME=/tmp/data \
  -e WEB_HOST=::1 -e WEB_PORT=18081 "$web_image")
ready=false
for attempt in $(seq 1 20); do
  if docker exec "$sync" curl --noproxy '*' --silent --fail --max-time 2 'http://[::1]:19849/ready' >/dev/null && \
     docker exec "$sync" curl --noproxy '*' --silent --fail --max-time 2 'http://[::1]:18081/sqlite3.wasm' >/dev/null; then
    ready=true; break
  fi
  sleep 1
done
[ "$ready" = true ]
for port in 19849 18081; do
  if docker exec "$sync" curl --noproxy '*' --silent --max-time 2 "http://127.0.0.1:$port/" >/dev/null; then
    echo 'Unexpected IPv4 acceptance in IPv6-only fixture' >&2; exit 1
  fi
done
printf '%s\n' '{"sync_ipv6_loopback":true,"web_ipv6_loopback":true,"ipv4_denied":true}'
