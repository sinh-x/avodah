# AVO-121 qualification ledger — 2026-11-14

**Source implementation delivered; full ticket acceptance NOT COMPLETE.** No
production deployment, gateway activation, host change, real Jira push, private
production-data read or human UAT was performed. This ledger is implementer
narrative, not independent review or operator approval.

## Commits / location

Selected canonical ticket checkout:
`/home/sinh/.treehouse/avodah-58b961/1/avodah`, branch
`feature/AVO-121-server-browser-hardening`, based on
`be1a8d5c912e90f7524c5a2a04e250251e09b087`.
The repository identity remains `/home/sinh/git-repos/sinh-x/tools/avodah`;
its separate develop checkout was not modified or merged.

| Phase | Source delivery |
|---|---|
| P1 |839e8aa pairing boundary, enrollment limits, origin/method policy, loopback, tested route contract |
| P2 |67fb2ad browser/native transport seam, scoped storage/identity, active REST credentials, fail-safe merge/ack, explicit browser WS exclusion |
| P3 |0ed2bae listener precedence/validation, actual Docker port behavior, clean Jira-off/private live opt-in contract |
| P4 |5b3d0d2 meaningful readiness/dependency probes, private code-file channel, SQLite recovery, runbook, CI coverage and checksum-pinned browser inputs |
| P5 |this ledger and owner handoff only; installed/device/human qualification remains gated |

## Executed source evidence

Direct child exits were used, not the legacy masked test wrapper.
- `cd mcp && dart test --reporter expanded`:460 tests passed on P4 candidate.
  Includes synthetic real HTTP/WS auth/nonmutation/upstream-denial/revocation,
  enrollment/preflight/origin bounds, readiness/optional dependency distinction,
  invalid startup with no directory side effects and listener precedence tests.
- `cd phone && flutter test --reporter expanded`:108 tests passed; includes
  seven-family pull/replay/full push, failed merge watermark and partial push
  retention, current REST credential rotation/forget and scoped node persistence.
- `cd packages/avodah_core && dart pub get && dart test`:288 tests passed.
  Offline resolution initially failed from cached incompatible analyzer constraints;
  online pub resolution succeeded. No production integration was contacted.
- `python3 -m unittest discover -s tool -p test_private_backup.py -v`:7 tests
  passed in0.204s on tiny isolated fixtures; see operations runbook for limits.
- `docker compose config --quiet`:passed. No container build/start performed.
- Changed MCP analyzer:No issues found. Phone analyzer:no errors/warnings,
  style/pre-existing informational findings only.
- Flutter release JS web build `/avodah/`:passed during P2. Final build includes
  checksum-verified SQLite WASM/worker inputs from tool/fetch-web-assets.sh;
  build outcome is recorded in the implementation handoff, not browser UAT.
- Hosted CI extended for core/phone/recovery/Compose/web but **not executed here**.

Toolchain:Dart3.10.8, Flutter3.38.9 (Nix-wrapped revision nixpkgs000).
Resolved local dependency-lock SHA256 (locks are currently ignored by repository):
- MCP:`1e17fb1e6c85c17a0ab2a841c887c73cfac6ed2a3d63efd7d058c5e1b594ab35`
- Phone:`ec506a6d6d614c6d597b8aefa5e6a964417fe680a052d3958959338f1d8e97e0`
- Core:`2394b5bfea5fb6d607a63c49b3289248316429708b7e85830178ae7584738357`
These hashes describe this execution, not reproducible checked-in release inputs.
Retain exact locks/build inputs privately for an authorized candidate build.
Image/base digests and installed bundle correspondence:UNKNOWN/unbuilt, not inferred
from OCI labels or version strings. No source→installed provenance claim.

## Required nonpassing gates / next work

1. Independent security review of exact candidate, expanded adversarial/concurrent
   enrollment and full seven-family state negative matrix; PA-supported route/WS
   handshake contract must be confirmed by its owner. Current tests sample state,
   not every mandatory TS subcase or complete cryptographic audit.
2. Real container/native IPv4/IPv6/nonloopback-observer listener qualification,
   nondefault installed routes, dead/stalled DB/static/PA fault injection and
   measured<=120s health detection. Compose rendering is not startup evidence.
3. Real HTTPS browser pairing/reload/restart/tabs, denied/quota storage and lost
   confirmation recovery, offline/concurrent/tombstone convergence, keyboard,
   375px/200% usability and clean runtime asset observation. Source tests/build
   do not pass TS-5..TS-7. Storage rollback can remain uncertain if storage itself
   prevents retaining the just-issued token: operator reconciliation is required.
4. Separately authorized Android regression and explicit legacy unscoped-token
   migration/revoke-and-reenroll before rollout. Existing unscoped secrets remain
   private; no guessed server association or silent cross-server forwarding.
5. Actual mocked Jira enabled/disabled/worklog-trigger matrix with egress blocked,
   credential validity/effective opt-in inspection at authorized live rollout;
   current service suite is not a complete TS-9 acceptance matrix.
6. Operator-selected backup destination and effective production UID/GID/ACL matrix;
   NX-070 daily scheduling, missed/failed backup alarms and RPO<=24h proof. Full
   restored paired two-way HTTP sync, large fixture<=60min RTO, interruption/power
   failure/actual ENOSPC and production backup verification remain outstanding.
7. Pin release build/base inputs, build immutable sync/web images, rehearse schema
   upgrade/rollback and compare later installed image/bundle correspondence.
8. DFC-004 secure routing/containment removal and NX-070 host readiness, each with
   separate exact rollout authority. P1 dossier was sent to DFC-004 before any
   unsafe exposure. Final source review, hosted CI, installed, browser, Android
   and Sinh's product UAT evidence must remain distinct.

TS-1..TS-14 are **not fully passed**; source subsets above are not a scope deferral.
No operator disposition waiving remaining criteria was obtained. AVO-118 session
issue and AVO-120 notification features remain separate. Do not mark ticket done
or open unsafe routes based on the implementation commits alone.
