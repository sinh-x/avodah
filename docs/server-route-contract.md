# AVO-121 / DFC-004 backend contract

Candidate source: this branch, P1 commit (see Git history). Not a deployed-image
claim or authorization to remove gateway containment. Both backend defaults are
loopback: sync 127.0.0.1:9847 and static web 127.0.0.1:8080. IPv6 uses explicit
`--host ::1` (IPv6-only). Nonloopback sync requires `--allow-nonloopback` for
isolated development. WEB_HOST is a deliberate static development override.

Gateway strips `/avodah` once. Route **all** `/avodah/api/*` and native
`/avodah/ws` / `/avodah/ws/session` to sync, never directly to PA9848; static paths
only to web. Do not fall through on 403/404/502. Preserve Authorization and
X-Av-Node-Id / X-Av-Pair-Token. PA credentials/approval remain independent.

| Internal path | Methods | Authentication |
|---|---|---|
| /, /health | GET | minimal public liveness |
| /api/sync/status | GET | public needsPairing only |
| /api/sync/pair/start, /confirm | POST | human-code enrollment |
| /api/sync/pair | DELETE | valid exact device, confirmed self-revoke |
| /api/sync/deltas | GET, POST | valid exact device |
| /api/config/categories | GET | valid exact device |
| /api/config/category-chips | GET, POST, DELETE | valid exact device |
| other /api/* | GET, POST, PUT, PATCH, DELETE | valid device then upstream PA |
| /ws, /ws/session | native GET upgrade | valid device then upstream PA |

Reserved unknown sync/config paths return JSON404. Other API unknown paths
receive upstream status. Unsupported protected methods are auth-first403 or405.
Missing, invalid, malformed, wrong-node and revoked credentials return403 with
PAIRING_REQUIRED and no protected data or upstream call. Revoke closes tracked
active native WS pairs; new invalid upgrades do not contact upstream. PA403 is
preserved without PAIRING_REQUIRED. Upstream failure is bounded502.

`SYNC_ALLOWED_ORIGINS` is an explicit comma-separated exact scheme/host/port
allowlist, e.g. the actual shared HTTPS origin (no path). Default denies every
Origin-bearing request. Native requests without Origin still require pairing.
No reflected/wildcard/null/suffix origin. Known route OPTIONS is local204 only
for allowed method/Content-Type,X-Av-Node-Id,X-Av-Pair-Token; otherwise403.
Enrollment preflight works before pairing. CORS never grants device authority.

Enrollment:300s, one in-flight operation/node,32 pending/in-flight challenges,
5 failed proofs,10 starts/minute/socket source and100 global; no trust in XFF.
The loopback proxy shares the source budget unless a future reviewed gateway
identity contract is added. Bodies stream-limited to8KiB (deltas5MiB),3s idle
bound. Codes go only to operator-selected PAIRING_CODE_FILE in a0700 private
directory with a0600 file (umask077), never Docker logs or TTY collectors. Without
this private channel enrollment fails closed. Operator reads the most recent
challenge privately; never publish the file or include it in backup artifacts.
Browser interactive WS is intentionally unavailable; tokens never belong in URLs.

## Executed isolated evidence
`cd mcp && dart test test/services/sync_http_security_test.dart
 test/services/sync_api_service_test.dart test/integration/sync_roundtrip_test.dart`
(direct invocation on one line) passed38 tests during P1. Synthetic real HTTP/WS
fixtures prove protected-route missing/invalid/wrong-node/malformed/revoked
negatives, unchanged chip/watermark/clock/lastSeen/upstream, valid chip control,
PA denial, exact-origin/preflight/method handling, additional-device enrollment,
proof replay/expiry/failure bounds/body bound/rate limit, echo and active revoke.
No real HTTPS, container listeners, Android, independent review or live exposure
has been qualified. These remain mandatory gates; do not infer them from this file.
