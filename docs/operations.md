# Private operations and recovery

No live service, secret, ownership or production-data change is authorized by
this runbook. NX-070 owns startup, scheduling, certificate lifecycle and alerts.
DFC-004 owns shared HTTPS. Docker restart unless-stopped restarts exited
containers; an unhealthy healthcheck alone **does not restart** a container.

## Health and access

GET /health is sanitized liveness; /ready performs a bounded DB settings-table
read. GET /dependencies independently reports PA reachable/auth-unavailable/
unavailable and Jira disabled/configured-unavailable/configured-unverified.
Jira credentials existing is not proof of a valid working integration. Optional
PA/Jira failure does not fail CRDT readiness. Docker probes use30s interval,
5s timeout,3 retries,30s startup; requests are bounded3s (DB/PA2s). Web probes
request index, SQLite WASM and worker, not unconditional /health. Measure actual
failure detection<=120s at qualification; source settings are not a measurement.
IPv6-only/custom-host deployments need corresponding probe URL overrides.
Logs rotate3×10MiB. NX-070/operator must connect health/backup-age alarms to a
real sink; none is silently installed here.

Before any access remediation, privately record service effective UID/GID, mount
ownership, all parent traversal modes and ACLs (`stat`, `namei -l`, `getfacl`),
without reading payloads. Review only DB, config.json/config.toml, node-id,
Jira credentials, WAL/journals, pairing-code channel and backups. Target0700
directories/0600 sensitive files or narrowly justified service-group equivalents.
Container entrypoint sets umask077 for new state. It does not repair old0644
files or prove ACL secrecy. No broad recursive chown/chmod. Production UID/ACL
matrix and minimal authorized remediation are still gates.

PAIRING_CODE_FILE is an explicit private operator channel: parent0700/file0600,
no symlink, umask077. Never point it at logs or a public mount. TTY output may be
collected by Docker, so is not used. Only the latest requested challenge is shown;
coordinate one human enrollment at a time. Code expires at300s server-side.
Do not include this ephemeral code file in backup inventory or artifacts.

## Recovery tool

`python3 tool/private_backup.py --help`; stdlib SQLite backup API, no scheduler
or network. Explicit source/destination paths only. Config/identity writers must
be quiesced by their owner before using --quiesced; the flag is an assertion,
not proof the tool stopped services. SQLite snapshot handles live WAL correctly.
Never raw-copy an active DB or start another sync writer against it.

Prepare operator-selected private local backup directory outside repositories,
source/config paths and exported artifacts. Its parent must already exist.
Example **synthetic/authorized paths only**:

```sh
umask 077
python3 tool/private_backup.py backup --data /private/fixture/data \
  --config /private/fixture/config --destination /private/backups \
  --revision EXACT_SOURCE_COMMIT --quiesced --apply-retention
python3 tool/private_backup.py restore --generation /private/backups/GENERATION \
  --destination /private/new-isolated-restore --expected-schema VERIFIED_SCHEMA
```

Backup copies config.json/config.toml when present, mandatory node-id, optional
Jira credentials and consistent avodah.db (pairing material is in SQLite).
Manifest/hashes are private0600, staging0700; integrity/schema/membership verified
before fsynced atomic promotion. A failed generation never deletes last good.
Optional retention verifies every generation before removing older sets, retaining
7 distinct daily +4 distinct weekly recovery points (overlap is possible).
Quiesce external config writers throughout capture; metadata checks also detect
obvious concurrent changes. No full external identity-transaction guarantee is
claimed if the quiescence assertion is false.

Restore refuses **any existing destination** and incompatible declared schema,
validates checksums/integrity, and leaves source backup untouched. Recovery output
is flat: point isolated AVODAH_DATA_DIR and AVODAH_CONFIG_DIR at that new directory
or privately place members into separate new data/config directories. Never point
an isolated instance at live DB/config. Verify counts, semantic values, node
identity and synthetic paired two-way HTTP sync before accepting recovery. Do not
print or export pairing/Jira values. Stop isolated instances and clean fixtures.

Executed Python unittest:7 tests, WAL snapshot with live fixture connection,
identity/paired material and private mode preservation, corruption/path traversal,
missing identity, schema mismatch/existing-target refusal, simulated disk-full,
retention. Disposable recovery completes<1s on a tiny fixture (not production
scaling or end-to-end paired-sync acceptance). Current test checks stored pairing
bytes, not complete restored HTTP pairing. Interruption/power loss, actual ENOSPC,
large-fixture RTO and live backup remain qualification gaps.

Accepted local targets: daily RPO<=24h, isolated verified restore<=60min,7 daily
+4 weekly. NX-070 must schedule completion often enough and alert on failed or
missed runs/latest verified backup age>24h. No host timer/service is installed by
Avodah. Local-only recovery cannot survive host loss. Production backup payload
access and destination selection need separate operator authorization.

## Provenance and rollback

Record exact clean Git commit and `git status --porcelain`, Dart/Flutter versions,
pubspec and lock hashes, resolved Docker base digests, downloaded web-asset hashes,
image IDs/digests and candidate bundle checksums in a private rollout dossier.
OCI revision labels accept SOURCE_REVISION; unknown/default or mutable build tags
are not provenance. Docker builders/runtimes now pin exact Dart3.10.8/Flutter3.38.9/Caddy2.11.2
and Debian base digests in the Dockerfiles; MCP/core/phone dependency locks are
tracked and enforced. Public SQLite WASM/worker inputs are checksum-pinned.
Record OS package inventories too: apt indexes remain external mutable inputs.
Do not claim bit-for-bit reproducibility or installed correspondence from version
strings, source labels, or pinned bases alone.

Before upgrade verify prechange recovery and schema compatibility on disposable
copies. Existing chip migration remains additive/idempotent; schema rollback is
not automatically safe. Compare old/new schema and pairing credential behavior,
especially the explicit, verified legacy-native credential migration in
[browser-sync.md](browser-sync.md). Incompatible downgrade requires
forward recovery or restoration into **new isolated storage**, not live overwrite.
Retain old images and backups. Rollback must keep hardened gateway containment;
never reopen insecure config routes to make an old client work.
