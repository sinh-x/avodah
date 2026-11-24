# Shared notification inbox (AVO-126)

Avodah supports explicit computer-to-inbox sending and one opted-in Android
push target. The Android app and desktop **web viewer** read the same server
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
suppresses future queued pushes. An already in-flight/accepted push cannot be
recalled.

## Explicit sender

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
encode private context in IDs: the ID is sent through FCM. The CLI accepts HTTPS
or loopback HTTP, refuses redirects, reports JSON receipts and returns nonzero
on failure. `avo notify` never opens the local worklog database. Agents may use
this explicit command or the narrow HTTP API, not background workflow hooks.

## API contract, version 1

All bodies/responses are JSON. Requests are limited to 70,000 bytes. All actual
requests require credentials; OPTIONS is unauthenticated CORS preflight.
Notification routes are handled locally before the PA reverse proxy.

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

## Firebase-free native trial

An isolated Avodah-native foreground-listener trial is available without a
Firebase account or extra app. See [build, service limits and device acceptance](native-notification-trial.md).
It does not replace the FCM baseline until the overnight trial is accepted.

## Optional Android FCM setup

Operator/provider setup and installed-device acceptance are separate from local
implementation. Without configuration the inbox still works; send receipts
report `not-configured`. Do not treat a compiled APK as a verified push rollout.

1. Create/select an operator-owned Firebase project and register Android package
   `com.sinh_x.avodah_viewer`. Download its `google-services.json` into
   `phone/android/app/` (git-ignored). The Google Services Gradle plugin is applied
   only when that file exists, so Android can initialize Firebase natively even
   when Dart is not running. Do not put a service-account key in the APK.
2. Enable FCM HTTP v1 and give a dedicated server service account the minimum
   FCM send permission in that project. Mount its JSON key read-only outside the
   checkout. Set `GOOGLE_APPLICATION_CREDENTIALS` to that path and
   `AVODAH_FCM_PROJECT_ID` to the project ID in the sync server environment.
   OAuth tokens are minted/refreshed with only the `firebase.messaging` scope.
   Keep credentials and `notifications.sqlite3` private to the server user.
3. Build the APK from `phone/` with `flutter pub get` and
   `flutter build apk --debug` (or your separately provisioned release signing).
   Current release Gradle configuration uses debug signing; do not mistake this
   for production signing. Install only with operator authorization. Use an
   Android device with Google Play services, pair it, open Notifications, then
   choose **Enable / reconnect alerts** and grant notification permission.
   Initialization/registration is disabled by default; no permission prompt or
   FCM enrollment happens on a fresh unopted-in startup.
4. Only one phone can be enrolled. The same paired node may rotate its token;
   another node must wait for the owner to disable enrollment. After reinstall
   or lost-device revocation, a queued send clears the revoked registration;
   the new phone can then enroll. **Disable alerts** removes server registration
   first; an offline disable reports failure rather than claiming success.
   Reconnect and retry. Re-enable to repair registration/permission errors.

Push messages contain only generic Avodah text and the opaque record ID. They
use a high-priority notification payload so Android can show an alert while
backgrounded/locked without a long-running Avodah connection. Tapping opens the
inbox; opening it fetches authenticated content. Foreground use relies on the
inbox refresh, not a separate local system alert. Android force-stop requires
manually reopening the app; permission denial, Doze/OEM restrictions and network
conditions can delay or suppress delivery.

The durable outbox retries transient/network/429/5xx failures up to five attempts
with increasing delay, across server restarts. A typed FCM UNREGISTERED error
removes the matching stale token. Permanent failures stop retries; the inbox is
still retained. Enrollment does not replay old records that had no device at
send time. Retrying the original producer request returns `delivery` as
`not-configured`, `no-device`, `queued`, `accepted-by-fcm`, `failed` or `cancelled`.
`accepted-by-fcm` means provider acceptance, **not phone delivery**. Process
failure after provider acceptance but before persistence can resend an alert;
Android uses the record ID as its notification tag to replace duplicates.

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
and Firebase environment settings. Disable/revoke enrollment before discarding
a phone. Do not overwrite newer inbox records without an explicit data decision.

Serve behind the existing authenticated-device/TLS deployment boundary. Local
implementation does not certify gateway/security readiness (AVO-121/DFC-004).
Use restrictive file permissions, a private bind/reverse proxy, and request/rate
limits at the gateway. No deployment, Firebase provisioning or device changes
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
- Test denied Android permission, invalid/stale token, server restart, revoked
  pairing and provider failure. Confirm records remain accessible when push
  fails. Disable alerts and verify no further queued delivery.
- Explicitly delete a record; confirm removal on both devices and no resurrection
  on producer retry. Smoke-test Agent Review, sessions, timers and share capture.

Reference contracts: [FCM Flutter reception](https://firebase.google.com/docs/cloud-messaging/flutter/receive)
and [HTTP v1 authorization](https://firebase.google.com/docs/cloud-messaging/auth-server).
This shares enrollment/delivery boundaries with AVO-120 but implements none of
its prompt/response/approval-intent APIs and does not change that ticket.
