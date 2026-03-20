# Avodah Sync Server — Docker build
#
# Multi-stage build:
#   Stage 1 (builder): dart:stable — compile sync_server.dart to native binary
#   Stage 2 (runtime): debian:bookworm-slim — minimal runtime with SQLite3
#
# Build:
#   docker build -t avodah-sync .
#
# Run:
#   docker compose up

# ──────────────────────────────────────────────────────────────
# Stage 1: Build — compile Dart to native binary
# ──────────────────────────────────────────────────────────────
FROM dart:stable AS builder

WORKDIR /app

# Copy local dependency first (better layer caching)
COPY packages/avodah_core/ packages/avodah_core/

# Copy MCP package
COPY mcp/ mcp/

# Resolve dependencies
WORKDIR /app/mcp
RUN dart pub get

# Compile to native binary (no Dart VM needed at runtime)
RUN dart compile exe bin/sync_server.dart -o /app/sync_server

# ──────────────────────────────────────────────────────────────
# Stage 2: Runtime — minimal Debian image with SQLite3
# ──────────────────────────────────────────────────────────────
FROM debian:bookworm-slim

# Install SQLite3 shared library (required by sqlite3 Dart package)
# ca-certificates: needed for HTTPS connections (Jira API)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libsqlite3-0 \
        ca-certificates \
    && ln -s /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 /usr/lib/x86_64-linux-gnu/libsqlite3.so \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy compiled binary from builder stage
COPY --from=builder /app/sync_server /app/sync_server
RUN chmod +x /app/sync_server

# Volume mount points
RUN mkdir -p /data /config

# Default environment variables
ENV AVODAH_DATA_DIR=/data
ENV AVODAH_CONFIG_DIR=/config
ENV JIRA_ENABLED=false
ENV AGENT_API_URL=http://host.docker.internal:9848

# Sync server port (container always listens on 9847;
# host-side port is configurable via SYNC_PORT in docker-compose)
EXPOSE 9847

# Run sync-only server on fixed container port 9847
CMD ["/app/sync_server", "--port", "9847"]
