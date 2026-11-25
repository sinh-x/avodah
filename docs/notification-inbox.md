# Shared notification inbox (AVO-126)

Avodah supports explicit computer-to-inbox sending and user-enabled native
Android notification listeners. The Android app and desktop **web viewer** read the same server
records. This inbox is separate from Agent Review and has no PA approval,
prompt/reply, agent-resume, broadcast or automatic workflow behavior.

## Use

Open the bell button in the viewer. Each record has independent read/unread and
handled/unhandled controls, a full-text detail view, and editable remarks.
Opening a detail or dismissing a system alert does not change either state.
Remarks are notes, not replies or approval decisions.

The server is authoritative. The visible inbox refreshes every five seconds and
on resume; older records can be loaded. While disconnected, already displayed
records remain visible with a stale warning and edits disabled. There is no
persistent offline cache or offline edit queue. Close/reopen while offline does
not promise access to records. Every edit supplies its observed revision. A
409 conflict refreshes the list instead of silently overwriting another device;
failed remark saves show a selectable copy of the draft for reapplication.

On desktop, serve the existing Flutter web build over HTTPS. Open Notifications
and select **Pair this browser**, then enter the code printed on the sync server.
This uses the existing passcode/X25519 enrollment protocol, not a producer or PA
credential. Browser credentials are scoped to the server and node in secure
storage; use a trusted browser/profile and protect the origin from scripts/XSS.
Android uses its existing pairing. Revoking that pairing blocks inbox access and
closes its native stream on the next authorization check. An alert already shown
on the phone cannot be recalled.

## Explicit sender

For Docker, use the maintained [Compose notification setup](../DOCKER.md#notification-delivery-avo-126)
to pass the producer credential to `avodah-sync` and retain the notification store
for native streaming. No separate notification container is needed.

Provision a random `AVODAH_NOTIFICATION_SEND_TOKEN` of at least 32 characters
in the sync server environment and in the sender's secret environment. This
credential can only create notifications or retrieve a retry receipt for the
same ID/content. It cannot list/read/edit records, retrieve remarks, enroll a
phone, mutate tickets or call PA. Never put it in the app or browser.

```sh
# Load the credential from your secret manager, not a command-line argument.
export AVODAH_SERVER_URL=https://your-host/avodah
cd mcp
dart run bin/avo.dart notify --id 5b12b35e-c4cf-4f53-a263-f3d3290af782 \
  --title 'Review ready' --body 'Please review the completed work.'
```

Use a new random opaque ID for a new message. Reuse exactly the same ID, title
and body after a timeout or uncertain result. Matching retries never create
another record/job; different content with the same ID is rejected. Do not
encode private context in IDs: the ID is sent through the native event stream. The CLI accepts HTTPS
or loopback HTTP, refuses redirects, reports JSON receipts and returns nonzero
on failure. `avo notify` never opens the local worklog database. Agents may use
this explicit command or the narrow HTTP API, not background workflow hooks.

## API contract, version 1

All bodies/responses are JSON. Requests are limited to 70,000 bytes. All actual
requests require credentials; OPTIONS is unauthenticated CORS preflight.
Notification routes are handled locally before the PA reverse proxy. The legacy
`/push/device` endpoints and FCM outbox remain server compatibility APIs; the main
Android app no longer enrolls with them. Native alerts use the paired SSE stream
documented in [the listener guide](native-notification-trial.md#stream-and-recovery-contract).

| Method and path | Credential | Body / response |
| --- | --- | --- |
| POST `/api/notifications` | `Authorization: Bearer …` producer | `{id,title,body}`; 201 new or 200 matching retry; `{id,created,delivery}` receipt only |
| GET `/api/notifications?offset=0` | Device pairing | `{items:[…],nextOffset:null\|integer}`; pages of at most 100, newest first |
| GET `/api/notifications/{id}` | Device pairing | `{item:…}` |
| PATCH `/api/notifications/{id}` | Device pairing | `{revision,read?,handled?,remarks?}`; at least one changed field; `{item:…}` |
| DELETE `/api/notifications/{id}` | Device pairing | `{revision}`; `{item:{deleted:true}}` |
| GET `/api/notifications/push/device` | Device pairing | `{configured,enabled}` for this device; no registration token returned |
| POST `/api/notifications/push/device` | Device pairing | `{token}`; enroll/rotate this phone; `{enabled:true}` |
| DELETE `/api/notifications/push/device` | Device pairing | Disable this device and cancel its queued jobs; `{enabled:false}` |

Pairing headers are `X-Av-Node-Id` and `X-Av-Pair-Token`, verified by the existing
pairing service. A record contains `id`, `title`, `body`, UTC `createdAt`, integer
`revision` (initially 1), boolean `read`, boolean `handled`, and `remarks`.
IDs contain 1–100 ASCII letters/digits/underscore/hyphen; titles contain 1–200
characters; bodies contain 1–16,000; remarks contain 0–16,000. Unknown mutation
fields and wrong types are rejected. Common failures are 400 invalid input,
403 invalid credentials, 404 missing record, 409 stale revision/reused ID/another
phone enrolled, 410 retry of deleted ID, 413 oversized request, 415 wrong content
type and 503 unconfigured server push.

Records have no automatic expiry. Explicit deletion removes them from both
inboxes, clears active title/body/remarks and cancels queued pushes. An ID
`tombstone` remains to prevent resurrection by retries. This is logical deletion,
not secure erasure of SQLite free pages or prior backups. Apply your backup
retention policy separately. Offset pagination is not a snapshot: concurrent
inserts may shift pages; refresh to reconcile.

## Native Android alerts

The main app (`com.sinh_x.avodah_viewer`) now uses Avodah's native foreground
listener. No Firebase account, SDK, Google Play services or extra app is required.
The separate `.notification_trial` package remains available for isolated tests;
its different identity and loopback default do not change main-app settings.
See [build, service limits and device acceptance](native-notification-trial.md).

Build the main APK from `phone/` with `flutter pub get`, then `flutter build apk
--release --target-platform android-arm64 --build-number <higher-build-number>`.
Use a version code higher than the installed app and the same signing identity.
Release Gradle currently uses debug signing; this is not production signing.
Never uninstall, clear app data or force a downgrade to work around a mismatch.

After an authorized update, open Notifications and choose **Enable / reconnect
alerts** while the app is visible, granting Android notification permission when
asked. Existing server settings and pairing are retained by an in-place upgrade;
there is no automatic permission grant or listener startup. **Disable alerts**
stops locally, including while the server is unreachable. The ongoing native
status notification also offers **Stop**.

The listener maintains an authenticated HTTPS event stream over the existing
private route. Tailscale must remain connected when that route requires it.
Alerts show generic Avodah text; only an opaque record reference is streamed.
Tapping fetches the exact item from the authenticated inbox. Initial enable does
not announce old history; reconnect can replay missed references. Force-stop,
process death, reboot and Android service timeouts require reopening and enabling
again. Doze/OEM restrictions and network loss can delay or suppress alerts. There
is no overnight/battery reliability claim until measured on the actual phone.

The sender receipt's legacy `delivery` field still describes the unused provider
outbox, not native streaming. `not-configured` is expected in this deployment and
is neither native-alert success nor failure. Keep `AVODAH_FCM_PROJECT_ID` and
`GOOGLE_APPLICATION_CREDENTIALS` unset; no FCM setup is needed. A connected stream
or accepted inbox record does not prove Android alert presentation.

## Backup, rollout and rollback

Before any live rollout/database change, stop the server and back up its data
and configuration directories with restrictive permissions. Include the primary
CRDT/pairing database and the separate `notifications.sqlite3`; retain any
SQLite journal/WAL files when copying a stopped store. Verify a restore on a
non-live copy first. Never test against the operator's real database.

The notification store has independent schema version 3 and uses full SQLite
synchronous writes and transactions. An existing older notification database is
backed up with `VACUUM INTO` to a unique `.before-v3-<timestamp>` path before
transactional schema changes. A backup/migration failure aborts initialization;
newer schema versions are rejected. The CRDT database schema is unchanged.
To roll back, stop the server, preserve the current data separately, restore the
matching pre-rollout backup and previous binary/APK, and remove the new producer
settings. Stop the native listener and revoke pairing before discarding a phone. Do not overwrite newer inbox records without an explicit data decision.

Serve behind the existing authenticated-device/TLS deployment boundary. Local
implementation does not certify gateway/security readiness (AVO-121/DFC-004).
Use restrictive file permissions, a private bind/reverse proxy, and request/rate
limits at the gateway. No deployment or device changes
are implied by this guide.

## Operator acceptance checklist (not yet performed)

- Configure an authorized server/APK; pair Android and an HTTPS desktop browser.
- Send from the CLI, retry the same ID, and verify one record on both devices.
- Background and lock Android, send a new ID, and observe the generic system
  alert. Dismiss it and verify the inbox record remains unread and unhandled.
- Tap another alert from both background and cold-start states; confirm the
  inbox opens without sharing message text in the push payload.
- Change read/unread, handled/unhandled and remarks independently on each
  device; verify the other device refreshes. Race edits and verify 409 behavior.
- Disconnect; verify stale/offline feedback and retained remark drafts. Reconnect
  and verify convergence without silently queued writes.
- Test denied Android permission, expired pairing, server restart, revoked
  pairing and private-route interruption. Confirm records remain accessible when
  alerts fail. Disable alerts and verify no further delivery while stopped.
- Explicitly delete a record; confirm removal on both devices and no resurrection
  on producer retry. Smoke-test Agent Review, sessions, timers and share capture.

Reference contract: [native listener stream and recovery](native-notification-trial.md#stream-and-recovery-contract).
This shares enrollment/delivery boundaries with AVO-120 but implements none of
its prompt/response/approval-intent APIs and does not change that ticket.
