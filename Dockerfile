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
FROM dart:3.10.8-sdk@sha256:a2a76f3bc4d52ce15005a980cbb87db13d156b7cad2d2e686f97a977c3cf77cf AS builder

WORKDIR /app

# Copy local dependency first (better layer caching)
COPY packages/avodah_core/ packages/avodah_core/

# Copy MCP package
COPY mcp/ mcp/

# Resolve dependencies
WORKDIR /app/mcp
RUN dart pub get --enforce-lockfile

# Compile to native binary (no Dart VM needed at runtime)
RUN dart compile exe bin/sync_server.dart -o /app/sync_server

# ──────────────────────────────────────────────────────────────
# Stage 2: Runtime — minimal Debian image with SQLite3
# ──────────────────────────────────────────────────────────────
FROM debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc

# Install SQLite3 shared library (required by sqlite3 Dart package)
# ca-certificates: needed for HTTPS connections (Jira API)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libsqlite3-0 \
        ca-certificates curl \
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
ENV AGENT_API_URL=http://127.0.0.1:9848
ENV SYNC_HOST=127.0.0.1
ARG SOURCE_REVISION=unknown
LABEL org.opencontainers.image.revision=$SOURCE_REVISION

# Informational only under host networking; SYNC_PORT changes the process.
EXPOSE 9847
# New container-created secrets/data are private; existing mounts need metadata review.
COPY tool/sync-entrypoint.sh /app/sync-entrypoint.sh
ENTRYPOINT ["/bin/sh", "/app/sync-entrypoint.sh"]
