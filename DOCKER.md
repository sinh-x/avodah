# Avodah deployment contract

This is a runbook, not permission to change running services or private state.
DFC-004 owns HTTPS/prefix routing and NX-070 owns host startup, DNS, renewal,
backup scheduling and alerts. Keep gateway containment until independent security
review and exact rollout authority. See [route contract](docs/server-route-contract.md),
[browser delivery](docs/browser-sync.md) and [operations](docs/operations.md).

## Architecture

Browser/Android → trusted HTTPS `/avodah` → shared gateway:
- all `/api/*` and allowed native `/ws` routes → loopback sync9847;
- static bundle only → loopback web8080.

Sync protects configuration and CRDT with device headers, then proxies eligible
PA requests to loopback9848 retaining PA's independent authorization. No direct
API gateway→PA bypass and no API failure→SPA fallback. Public status/enrollment
are narrow exceptions. Core CRDT works when optional PA/Jira are unavailable.
Static Caddy preserves COOP/COEP and SQLite WASM MIME; it does not proxy APIs.

## Effective configuration

Sync port: `--port` > SYNC_PORT > config.json `sync.port` >9847.
Host: `--host` > SYNC_HOST >127.0.0.1 (no persisted host key).
Literal IPv4/IPv6 addresses only; ports1..65535. Invalid values exit before DB,
node creation, migrations or startup pulls. IPv6 loopback: `--host ::1`.
Nonloopback native development requires `--allow-nonloopback`; never use this
behind the shared production gateway. WEB_HOST defaults127.0.0.1; WEB_PORT8080
changes the actual static listener. SYNC_PORT changes the actual server listener,
not a Docker mapping. Host networking has **no ports publications**. If changing
ports (e.g. SYNC_PORT=19847 WEB_PORT=18080), DFC-004 must separately update its
upstream routes. No Avodah env variable rewrites the shared gateway.

Compose explicitly supplies9847/127.0.0.1, overriding persisted ports. Override
with a private `--env-file`, not an auto-loaded Jira-on override. There is no
tracked automatic override. Inspect any operator-local override before rollout;
legacy automatic overrides may still exist outside this clean checkout.

Variables: AVODAH_CONFIG and AVODAH_DATA select existing host directories mounted
read-write at /config and /data. Keep config.json, node-id, Jira credentials and
SQLite DB together for recovery. AGENT_PORT defaults9848. SYNC_ALLOWED_ORIGINS
must contain the exact trusted HTTPS origin (no `/avodah` path); default denies
browser Origin-bearing requests. Origin is not device authentication.

## Jira intent and private opt-in

A clean checkout genuinely defaults JIRA_ENABLED=false. Sinh's recorded live
intent is **enabled** using a private explicit JIRA_ENABLED=true opt-in. Preserve
that setting at separately authorized rollout; do not silently turn off a live
integration. Missing credentials reports configured/unavailable and does not
instantiate anonymous Jira writes. JIRA_ENABLED accepts true/false only. The
credential file is `/config/jira-credentials.json`, inside the read-write config
mount; restrict its access individually. No live Jira push is a test, including
startup/migration replay. Validate existing worklog push state before enabling.

## Existing-data rollout (operator-authorized only)

1. Record old source/image/DB schema and effective config metadata privately.
2. Verify one DB writer; do not run native sync alongside Docker on the same DB.
3. Take a separately authorized consistent private backup and isolated restore.
4. Build from a clean exact commit; record resolved base digests, dependency locks,
   downloaded WASM/worker checksums and output image IDs/digests. Mutable tags and
   OCI revision labels alone do not prove provenance. Do not assume historical
   containers were built from current source.
5. Render Compose with the chosen private env file without dumping secrets.
   Build with SOURCE_REVISION set to the checked full Git commit. Inspect image
   IDs before authorized replacement; never prune rollback images/resources.
6. Set explicit live Jira opt-in and trusted origin. Arrange PAIRING_CODE_FILE
   in a private0700 operator-selected directory with a0600 file (umask077).
   Operator reads the current human code privately, never via logs/TTY collectors.
   Without that explicit private channel enrollment fails closed.
7. Replace only the existing instance under its owner. Check loopback listeners,
   health, missing/invalid/revoked rejection, exact bundle/image and safe rollback.
   DFC-004 alone authorizes route containment removal. Browser/Android acceptance
   and legacy native scoped-credential migration remain separate rollout gates.

Use `docker compose --env-file /private/path config --quiet` for syntax checking.
Do not publish resolved environment or `docker inspect` payloads containing secrets.
`docker compose build` builds candidates; `up`/`down` have live effects and are not
verification shortcuts. Reverting to an old insecure image does not authorize
reopening old routes: retain hardened gateway containment during rollback.

## Safe diagnosis

Use bounded `curl --fail --max-time 3 http://127.0.0.1:9847/health` for liveness
and `/ready` for local CRDT readiness. `/dependencies` reports optional feature
status without credentials. Web health must read index.html plus required assets,
not only an unconditional `/health` response. Pairing403 ≠ PA denial ≠ PA502.
NX-070 owns PA service recovery; do not launch another unmanaged PA instance.
No destructive Docker prune or broad chmod/chown is part of this runbook.
