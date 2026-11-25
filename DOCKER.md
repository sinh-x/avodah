# Avodah Sync Server — Docker Deployment

Runs the Avodah CRDT sync server in a Docker container. The container handles:
- **Sync API** (`/api/sync/*`) — CRDT delta sync between desktop and phone
- **Notifications** (`/api/notifications` and `/api/notifications/*`) — shared inbox,
  explicit sender and native event stream, all in this server
- **HTTP proxy** (remaining `/api/*`) — forwarded to `pa serve` on the host (port 9848)
- **WebSocket proxy** (`/ws`) — forwarded to `pa serve` on the host (port 9848)

The phone uses the private HTTPS gateway. Sync and notification traffic reaches
this container (port 9847); agent traffic is proxied to `pa serve` (port 9848).
The phone does not connect directly to port 9848.

## Prerequisites

- Docker 20.10+
- Docker Compose v2 (`docker compose` command, not `docker-compose`)
- Existing Avodah data at `~/.local/share/avodah/` and config at `~/.config/avodah/`

## Quick Start

For an existing deployment, use the [safe sync-only rollout](#safe-sync-only-rollout-and-smoke-test)
instead; back up before starting a newer server against its databases.

```bash
# Build and start (detached)
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

The sync server is available at `http://localhost:9847`.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYNC_PORT` | `9847` | Listener port passed as `--port`; host networking has no port mapping |
| `SYNC_HOST` | `127.0.0.1` | Host/interface the sync server binds to; keep loopback-only behind Caddy |
| `AGENT_PORT` | `9848` | Port where `pa serve` listens on the host |
| `JIRA_ENABLED` | `false` | Enable Jira auto-push on worklog sync |
| `AVODAH_CONFIG` | `~/.config/avodah` | Host path to config directory (mounted read-write) |
| `AVODAH_DATA` | `~/.local/share/avodah` | Host path to data directory (mounted read-write) |
| `AVODAH_NOTIFICATION_SEND_TOKEN` | empty (sending disabled) | Random send-only producer credential, at least 32 characters; sync service only |

Load the producer credential privately from the operator's secret manager into the
Compose process environment and the sender's environment. Do not put it in a
command argument, committed file, image build argument or phone/browser app.
The current API accepts the credential as an environment variable, not a
`*_FILE` variable. Docker administrators can inspect container environment values;
restrict Docker access. An unset/short credential fails closed with HTTP 403 on
sends, while paired inbox access still works.

Compose reads the host's local `.env` next to `docker-compose.yml` for variable
substitution. Only variables declared under the service's `environment` are passed
to the container. The `.env` file itself is not mounted or copied into the image;
server build-context exclusions cover `.env` and `.env.*`. If the operator stores
the sender credential there instead of a secret-manager environment, keep that
file private and uncommitted. Do not print it or dump rendered container settings.

Non-secret settings can be set there as follows:

```env
SYNC_PORT=9847
SYNC_HOST=127.0.0.1
AGENT_PORT=9848
JIRA_ENABLED=false
```

## Volume Mounts

| Container path | Host path | Mode | Contents |
|----------------|-----------|------|----------|
| `/config` | `~/.config/avodah/` | read-write | `config.json`, `node-id`, Jira credentials |
| `/data` | `~/.local/share/avodah/` | read-write | `avodah.db` and durable `notifications.sqlite3` inbox/native event log |

> **Warning:** Only one sync server instance should access the SQLite database at a time. Running both the Docker container and the native `avodah-sync` binary simultaneously will cause SQLite locking errors.

## Notification Delivery (AVO-126)

No extra notification container is needed. The compiled sync server already
handles notification routes before its PA proxy. The normal Compose file passes
`AVODAH_NOTIFICATION_SEND_TOKEN` only to `avodah-sync`; the existing `/data` mount
preserves the inbox and native replay cursor log across restarts.
Notification records and pairing remain private server data.

### Native phone listener

Use the standard Compose setup. No external push-provider credentials or overlay
are needed. The native Android foreground listener connects directly to
`/api/notifications/events/stream` using its existing device pairing.

The updated main Android app uses this native listener while preserving its
normal app identity, configured server and pairing. An older installed APK must
be upgraded; changing Compose alone does not update the phone. Open Notifications
and explicitly enable/reconnect alerts after the upgrade. Follow the
[native listener guide](docs/native-notification-trial.md) for service/Tailscale
limits. The separate isolated trial build is still available; do not repoint it
at production data merely to test this configuration.

### Safe sync-only rollout and smoke test

The referenced deployment d-d5a0de passed isolated staging but paused before
production cutover on live-configuration admission. These commands do not resolve
that blocker or authorize access to its configuration. Do not repeat its staged
backup claims as checks of a newer candidate.

1. Confirm the authorized source/image and existing operator settings without
   printing credentials. Resolve any live-configuration access blocker first.
   Preserve the data/config mounts, pairing, Jira override, loopback listener,
   PA upstream and current private HTTPS route. Do not run a second server on
   these same databases.
2. Before any live database/schema change, stop **only** `avodah-sync`, take a
   private consistent backup of both data and config (including SQLite journals),
   retain the old image identity/configuration and verify restoration on an
   isolated copy. See [backup and rollback](docs/notification-inbox.md#backup-rollout-and-rollback).
3. Load the producer credential privately; validate with `config --quiet` rather
   than printing `config`, `env` or raw Docker inspection. Rebuild/recreate only
   the sync service, leaving the web service and gateway unchanged:

   ```bash
   # Native/base mode; automatically retains the usual local override.
   docker compose config --quiet
   docker compose up -d --build --no-deps avodah-sync
   ```

   `restart` alone does not rebuild the binary or apply new environment settings,
   including changed `.env` values.
4. Verify loopback health and unauthenticated rejection. Confirm the existing
   private gateway sends **both** `/avodah/api/notifications` and
   `/avodah/api/notifications/*` to sync-server9847 (or the chosen `SYNC_PORT`),
   stripping `/avodah`, before any PA9848 catch-all. The SSE route must be
   unbuffered with an idle timeout longer than its 15-second heartbeat. This is
   an external gateway-owner check: the repository Caddyfile serves web assets
   only, and changing it cannot repair that route. No gateway change is included
   in this Compose update.
5. From a sender with the same private credential, issue an explicit synthetic
   send using `avo notify` as documented in the
   [sender guide](docs/notification-inbox.md#explicit-sender). Reuse the same ID,
   title and body after an uncertain result. Confirm one inbox record, then
   observe the actual alert on the intended locked phone. Native mode can return
   `delivery: not-configured` because that legacy receipt field does not measure
   native streaming. It is not proof of failure or success of the phone alert.

There are no automatic build-completion/workflow hooks. A computer or agent sends
explicitly with the scoped sender command; the producer credential cannot read
or modify inbox records or act on PA. Phone installation, mode promotion, gateway
changes and overnight acceptance require their own operator authorization.

To roll back, stop only sync, preserve any newly accepted records and restore the
previous image/configuration. Do not overwrite current data with an older backup
without an explicit data decision.

## TLS Termination (Upstream Reverse Proxy)

The sync server speaks plain HTTP only. TLS is terminated by an upstream
reverse proxy (e.g. `drgnfly-caddy`) that fronts the container at
`https://drgnfly.tail10c2c6.ts.net/avodah` and forwards to `localhost:9847`.

The committed Compose configuration binds HTTP on the host's loopback interface
with `SYNC_HOST=127.0.0.1`; the sync server should not be exposed externally.
Only override this for isolated local testing where an upstream proxy is not in
use.

The phone connects to the upstream HTTPS URL (e.g.
`https://drgnfly.tail10c2c6.ts.net/avodah`); the upstream Caddy strips the
`/avodah` path prefix. Sync, configuration and notification routes must go to the
sync server; only the remaining agent routes should go to `pa serve` on the host.
Notification routing must include the exact collection path and its subpaths.

## Proxy Architecture

```
Phone ──HTTPS──→ drgnfly-caddy /avodah
  ├── /api/sync/* ──HTTP──→ localhost:9847 (avodah-sync)
  ├── /api/notifications[/*] ──HTTP──→ localhost:9847 (avodah-sync)
  ├── other /api/* ──HTTP──→ localhost:9848 (pa serve)
  └── /ws         ──HTTP──→ localhost:9847 (avodah-sync WebSocket proxy)

Host ──→ :9847 (Docker container — avodah-sync)
  ├── /api/sync/* Handled by sync server (CRDT delta sync)
  ├── /api/config/* Handled by sync server (category config)
  ├── /api/notifications[/*] Handled locally (inbox and native SSE)
  ├── other /api/* HTTP proxied ──→ host:9848 (pa serve)
  └── /ws         WebSocket proxied ──→ host:9848 (pa serve)

Host ──→ :9848 (pa serve — personal-assistant repo)
  ├── /api/*      Agent workflow API (inbox, teams, deploy, etc.)
  └── /ws         WebSocket real-time events
```

The Compose service uses `network_mode: host`, so `AGENT_API_URL` points to
`http://localhost:9848` to reach `pa serve` on the same host.

**If `pa serve` is not running:** Proxy requests return HTTP 502. Sync continues working normally — the sync API is always available regardless of agent API availability.

## Jira Integration

Jira sync is disabled by default. To enable:

```bash
JIRA_ENABLED=true docker compose up -d
```

Jira credentials must be present at `~/.config/avodah/jira-credentials.json`
(inside the existing read-write `/config` mount). A local Compose override may
already set `JIRA_ENABLED=true`; preserve it during sync-only updates.

## Building the Image

The multi-stage Dockerfile compiles `mcp/bin/sync_server.dart` to a native binary using `dart compile exe`, then copies only the binary and `libsqlite3` into a `debian:bookworm-slim` runtime image.

```bash
# Build only
docker compose build

# Build with no cache (after dependency changes)
docker compose build --no-cache
```

Expected image size: ~40–60MB (native binary + SQLite3 + minimal Debian).

## Troubleshooting

### Container fails to start — database locked

```
Error: SQLite error: database is locked
```

Another process has the database open. Stop the native `avodah-sync` binary before starting the container (or vice versa).

### Cannot reach agent API — 502 errors

```
/api/* requests return 502 Bad Gateway
```

`pa serve` is not running on port 9848. Start it:

```bash
pa serve --port 9848
```

Sync continues working. Only agent API requests (inbox, teams, deploy) are affected.

### Agent API host not reachable

With `network_mode: host`, `AGENT_API_URL=http://localhost:9848` should reach
`pa serve` on the host. Check Docker and `pa serve` first:

```bash
docker --version
curl http://localhost:9848/api/health
```

If you run without host networking, set `AGENT_API_URL` to a reachable host name
or LAN IP instead:

```env
AGENT_API_URL=http://192.168.1.x:9848
```

### Image size too large

If the image exceeds your target, rebuild without cache:

```bash
docker compose build --no-cache
docker system prune -f  # remove dangling layers
docker images avodah-sync
```

### Validate Compose without exposing credentials

```bash
docker compose config --quiet

# Repository regression check; uses only synthetic values and ignores local .env.
python3 tool/check-compose-notifications.py
```

Do not dump the rendered Compose configuration or container environment after
adding the producer credential. The regression check does not deploy containers,
read live configuration or prove phone delivery.

### Check sync server health

```bash
curl http://localhost:9847/
# Expected: {"status":"ok","service":"avodah-sync"}
```
