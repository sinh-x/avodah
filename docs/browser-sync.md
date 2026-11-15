# Browser pairing and sync

Web delivery supports CRDT and supported PA REST, not interactive sessions.
Open the trusted HTTPS `/avodah/` installation. Pairing uses the existing private
human-code/X25519/HMAC flow, not PA credentials. A second device may enroll even
when public status says the server already has devices. Pairing does not revoke
other devices. A missing/revoked device triggers one initial pairing prompt per
app run; Settings → Technical → Pair this device permits deliberate retry.

Browser transport uses fetch with redirect=error, same-origin HTTPS only and no
cookies. Tokens are request headers, never query parameters. Storage is browser
origin localStorage with deployment-base-scoped keys; same-origin sibling scripts
and XSS can read/act on it. It is not encrypted-at-rest/HttpOnly/hardware storage.
Each browser profile/server base has an independent random stable node ID. Every
request re-reads the active credential, including REST providers and other tabs.
Storage failure is not remembered success. Local CRDT remains independent of auth.

Before confirming a code, both transports durably stage a server/node-scoped
pending credential, which no normal consumer uses. If storage is denied, no
confirmation is sent. If a successful confirmation response is lost or active
storage later fails, reload offers **Finish pairing verification**: authenticated
GET `/api/sync/pair` verifies that exact saved credential, then activates it only
after durable storage succeeds. No new node/pairing is created for recovery.
Explicit403 clears a rejected pending candidate; offline/502 retains it privately
for retry. Local Forget clears active and pending state but never local CRDT.

Settings distinguishes confirmed remote Revoke from Forget locally (which warns
that server trust can remain). Network failure cannot report confirmed revoke.
PA403 remains a PA feature denial, not PAIRING_REQUIRED. Sync403 requires pairing;
network/TLS failure is offline. No fallback to unauthenticated PA or SPA.

Native TLS/certificate approval remains a conditional native implementation;
WebSocket headers remain native-only. Browser Session shows an explicit unavailable
message and the transport also rejects accidental session calls.

### Existing phone upgrade (server first)
Deploy the hardened server before the updated phone. Pairing → **Use existing
phone pairing?** displays the normalized destination and asks the user to confirm
it is the original trusted server. Cancel sends nothing. Only that explicit action
sends the saved credential and unchanged node ID to authenticated GET
`/api/sync/pair`. HTTPS trust is still checked; redirects, denial, offline and
storage failure do not claim migration. On success it binds the saved credential
to that exact deployment, verifies secure persistence and keeps the old secret
privately for old-app rollback. Another server cannot silently import it. Local
Forget/Revoke removes that legacy fallback too, preventing automatic resurrection.
An older server without the verification route must be upgraded first. A revoked
legacy credential is not recovered by public enrollment or an identity-name reset;
use the existing trusted operator/device-management owner. Local records are kept.
Automated HTTP/storage/UI regressions cover this path; actual Android upgrade
and device trust behavior still need separately authorized observation.

Partial push acknowledgement throws so local pending changes are retained. Failed
pull merges do not advance the receive watermark; replay is idempotent. Server
partial batches likewise retain the receive watermark.

Executed:108 phone tests, including current-credential REST rotation/forget,
server-scoped node persistence, seven-family pull/replay/full-push and failed
merge/partial acknowledgement. `flutter build web --release --base-href /avodah/`
succeeded (JS application plus SQLite WASM assets; optional whole-app WASM dry-run
warns about third-party secure-storage plugin). Analyzer: no errors/warnings,
existing/style informational findings remain. No real HTTPS browser observation,
375px/200% keyboard UAT or authorized Android-device regression has been claimed.
