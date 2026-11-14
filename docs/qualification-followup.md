# AVO-121 PR #199 follow-up

This supplements, not rewrites, the historical qualification ledger. Source fixes
and automated fixtures are not independent security review, device/human UAT or
production rollout permission. No production mounts/services are used by tests.

## Resolved source issues

- Explicit legacy native pairing import (`479e755`): human confirms normalized
  original trusted server, side-effect-free paired GET verifies exact node/token,
  redirects/denial/offline/storage failure do not claim success. Durable destination
  binding prevents cross-server import and Forget prevents fallback resurrection.
  Original node/local CRDT retained; old token kept privately for old-app rollback.
- Native certificate fingerprinting uses the reviewed crypto package SHA256,
  rather than the incorrect hand-rolled implementation. wss URL migration no
  longer downgrades TLS. Browser storage-failure rollback can use an ephemeral
  in-memory credential without first writing the failing storage again.
- Static Caddy admin is off, removing its competing :2019 listener. Actual peer
  container probes also caught that a site hostname alone does not restrict
  Caddy's socket bind: an explicit `bind {$WEB_HOST:127.0.0.1}` now does so.
  This does not change the shared gateway's separately owned admin endpoint.
- CI Linux failure traced to old plugin-vendored JSON literal operators becoming
  warnings-as-errors in new Clang. A compiler-checked, target-specific exception
  keeps that one third-party deprecation as a warning; all other -Werror checks
  remain. No secure-storage major-version/key-format upgrade is used as a workaround.
- Flutter/runner, Docker base digests and public web assets are pinned; MCP/core/
  phone dependency locks tracked/enforced. Dockerignore now includes required
  entrypoint/asset-fetch scripts and excludes local env/Git/cache/build state.
  Flutter bundles web resources locally rather than depending on a public CDN.
- Streaming bodies have total deadlines plus cancellation, including dribbling
  chunked senders; PA response buffering is limited16MiB. Proxy oversized requests
  receive413 and upstream failures remain bounded502, never fallback HTML.
- Duplicate/malformed credential headers fail closed. Revocation fences late WS
  tracking and every proxied frame as well as new handshakes; timed-out upstream
  WS attempts close their own HTTP transport.
- Pull captures watermark before asynchronous table extraction, so a concurrent
  write cannot be skipped. Merge batches run in serialized SQLite transactions;
  partial failure retains received watermark. Streamed mutations re-check device
  authority inside the commit transaction, and PA forwarding re-checks after
  receiving the body: a completed revoke fences a previously admitted slow POST.
  Chip changes are transactional and acknowledged only after commit. Jira scans/posts are serialized to
  avoid duplicate acknowledged worklogs from concurrent sync batches; empty
  credentials cannot produce anonymous requests. Errors/logs are sanitized.
- Recovery validates directory ownership, rejects symlink destination/lock/
  manifest and preserves the last good set on simulated interruption/disk error.
  Retention tests assert seven recent days/four distinct weeks, not just row count.

## Automated coverage added

Phone upgrade/storage/HTTP/redirect/cancel tests; seven-family full DB-state
nonmutation comparisons after every protected auth rejection; global/per-source
budgets and32 concurrent challenge cap/expiry; total stream deadline/cancellation;
concurrent pull/write and concurrent independent-field merge; partial watermark;
mock-only Jira enabled/disabled/missing/empty/error worklog push and acknowledged
replay/concurrent duplicate prevention; recovery interruption/symlink/retention.

See the PR's current exact-head CI and subsequent isolated runtime report for
executed counts/artifact identities. Full actual Android regression, independent
review, operator backup destination/UID/ACL/scheduling and later installed shared
HTTPS acceptance remain external gates, not source fixes that an implementer can
self-certify. DFC-004 containment remains until actual backend/security readiness.
