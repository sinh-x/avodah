# Avodah (עבודה)

Local-first task management, daily planning and time tracking, with a Dart CLI,
MCP tools and Flutter Android/browser client.

## Current architecture

- `packages/avodah_core`: shared CRDT documents and Drift/SQLite schema.
- `mcp`: CLI (`bin/avo.dart`), MCP (`bin/server.dart`), authenticated HTTP sync
  (`bin/sync_server.dart`). One sync server per data directory.
- `phone`: Flutter local SQLite client; seven-family two-way CRDT over paired
  HTTPS. Browser credentials persist per origin/deployment; native TLS remains
  platform-specific. Browser interactive sessions are explicitly unavailable.
- Shared HTTPS `/avodah` gateway routes API/native WS through sync9847; static
  assets go to web8080. PA9848 has independent authorization; pairing grants no
  PA approval. Both backend listener defaults are loopback-only.

No Isar, mDNS discovery or transport E2E-encryption claim is made for this delivery.
TLS protects the network; device tokens authenticate requests. Browser same-origin
scripts/XSS can access origin storage. Never put pairing/PA credentials in URLs.

## Development (from repository root)

```sh
(cd mcp && dart pub get && dart run bin/avo.dart --help)
(cd mcp && dart test)
(cd packages/avodah_core && dart pub get && dart test)
(cd phone && flutter pub get && flutter test)
sh tool/fetch-web-assets.sh
(cd phone && flutter build web --release --base-href /avodah/)
```

Use isolated disposable data for native server tests via AVODAH_DATA_DIR and
AVODAH_CONFIG_DIR; do not start a second writer on existing/live data. Browser
pairing requires trusted same-origin HTTPS and an explicit exact-origin server
allowlist, not disabled authentication. See [deployment](DOCKER.md),
[route contract](docs/server-route-contract.md), [browser](docs/browser-sync.md),
[operations/recovery](docs/operations.md), and [qualification](docs/qualification.md).

Jira is genuinely off in clean checkouts; intended live enablement is explicit
private operator opt-in, never a real push as a test. Gateway/host/service changes
and real Android/human acceptance require their own authorization.

## Releases

See [CHANGELOG.md](CHANGELOG.md). Version strings and labels do not establish
source/image identity. Record exact clean commit, dependency/build inputs, image
IDs/digests and installed web checksums before a reversible authorized upgrade.

MIT. Work as worship.
