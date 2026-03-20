# Avodah Sync Server — Docker Deployment

Runs the Avodah CRDT sync server in a Docker container. The container handles:
- **Sync API** (`/sync/*`) — CRDT delta sync between desktop and phone
- **HTTP proxy** (`/api/*`) — forwarded to `pa serve` on the host (port 9848)
- **WebSocket proxy** (`/ws`) — forwarded to `pa serve` on the host (port 9848)

The phone connects only to this container (port 9847). The container transparently proxies non-sync traffic to `pa serve`, so the phone has no knowledge of port 9848.

## Prerequisites

- Docker 20.10+ (for `host.docker.internal` support on Linux)
- Docker Compose v2 (`docker compose` command, not `docker-compose`)
- Existing Avodah data at `~/.local/share/avodah/` and config at `~/.config/avodah/`

## Quick Start

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
| `SYNC_PORT` | `9847` | Host-side port the sync server is reachable on |
| `AGENT_PORT` | `9848` | Port where `pa serve` listens on the host |
| `JIRA_ENABLED` | `false` | Enable Jira auto-push on worklog sync |
| `AVODAH_CONFIG` | `~/.config/avodah` | Host path to config directory (mounted read-only) |
| `AVODAH_DATA` | `~/.local/share/avodah` | Host path to data directory (mounted read-write) |

Set these in a `.env` file next to `docker-compose.yml`:

```env
SYNC_PORT=9847
AGENT_PORT=9848
JIRA_ENABLED=false
```

## Volume Mounts

| Container path | Host path | Mode | Contents |
|----------------|-----------|------|----------|
| `/config` | `~/.config/avodah/` | read-only | `config.toml`, `node-id`, Jira credentials |
| `/data` | `~/.local/share/avodah/` | read-write | `avodah.db` (SQLite database) |

> **Warning:** Only one sync server instance should access the SQLite database at a time. Running both the Docker container and the native `avodah-sync` binary simultaneously will cause SQLite locking errors.

## Proxy Architecture

```
Phone ──→ :9847 (Docker container — avodah-sync)
  ├── /sync/*     Handled by Docker (CRDT delta sync)
  ├── /api/sync/* Handled by Docker (CRDT delta sync)
  ├── /api/config/* Handled by Docker (category config)
  ├── /api/*      HTTP proxied ──→ host:9848 (pa serve)
  └── /ws         WebSocket proxied ──→ host:9848 (pa serve)

Host ──→ :9848 (pa serve — personal-assistant repo)
  ├── /api/*      Agent workflow API (inbox, teams, deploy, etc.)
  └── /ws         WebSocket real-time events
```

The container uses `host.docker.internal` (Docker 20.10+ built-in DNS) to reach `pa serve` on the host. This is configured via `extra_hosts: ["host.docker.internal:host-gateway"]` in `docker-compose.yml`.

**If `pa serve` is not running:** Proxy requests return HTTP 502. Sync continues working normally — the sync API is always available regardless of agent API availability.

## Jira Integration

Jira sync is disabled by default. To enable:

```bash
JIRA_ENABLED=true docker compose up -d
```

Jira credentials must be present at `~/.config/avodah/jira-credentials.json` (mounted read-only into `/config/jira-credentials.json`).

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

### host.docker.internal not resolving

Requires Docker 20.10+. Check:

```bash
docker --version
# Docker version 20.10.x or higher required
```

On older Docker or Podman, set `AGENT_API_URL` to the host's LAN IP instead:

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

### View container environment

```bash
docker compose exec avodah-sync env | grep -E 'AVODAH|JIRA|AGENT|SYNC'
```

### Check sync server health

```bash
curl http://localhost:9847/
# Expected: {"status":"ok","service":"avodah-sync"}
```
