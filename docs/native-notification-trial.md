# Native Android notification listener

Avodah itself receives private notification references and generates Android
alerts. The main app now uses this native path, with **no Firebase SDK,
account/configuration or additional ntfy app**. Sinh explicitly selected main-app
native delivery. The isolated trial package is still available for synthetic
checks. This selection is not evidence of overnight reliability or human device
acceptance. The shared inbox and read/handled/remarks behavior are unchanged.

## Supported service model and limits

The native listener is a user-started Android `specialUse` foreground service.
Its manifest declares the purpose: visible private-server connectivity status,
a Stop control and notification reception, not general background data sync.
Android documents this type for valid foreground-service purposes not covered
by another type; ntfy uses the same model for its subscriber service. This is
not a claim of Google Play review approval or measured device eligibility.

Target SDK remains **35**. The trial does not misuse `dataSync` (which has an
Android 15 six-hour daily background limit), lower the target SDK, acquire wake
locks, request battery-optimization exemptions or start itself at boot. It
starts only from the visible app after an explicit button press and notification
permission. Android 8+ is required for this listener. It has an ongoing status
notification with **Stop**; disabling also works locally without the server.
If notifications or either notification channel are denied, it cannot continue
claiming usable alerts.

The service is `START_NOT_STICKY`: process death, force-stop, reboot or an Android
service timeout requires reopening Avodah and enabling again. App/Flutter UI
closure does not itself stop a still-running user-started service. Doze, OEM
battery policy and Tailscale availability may suspend its network. There is no
claim of overnight reliability, latency or acceptable battery use until measured
on the actual phone. There is **no polling fallback** for background alerts.
Foreground inbox refresh remains the existing five-second UI behavior.

## Main app and isolated build

The standard main build uses native alerts with the existing normal package ID,
server settings and pairing. Follow [main-app build and opt-in](notification-inbox.md#native-android-alerts)
for a compatible in-place update. Upgrades do not auto-start the listener or grant
notification permission. The isolated build below remains a separate app and
must not be used to overwrite or copy production app data.

```sh
cd phone
flutter pub get
AVODAH_NOTIFICATION_TRIAL=true flutter build apk --debug
```

The output is `phone/build/app/outputs/flutter-apk/app-debug.apk` when referenced
from the repository root. It has app ID
`com.sinh_x.avodah_viewer.notification_trial` and label
**Avodah notification trial**. Verify these and the SHA-256 before any authorized
install. It cannot replace the normal app ID or share its app-private data or
pairing. Debug signing is not production signing. Subsequent standard builds
reuse the output filename, so identify candidates by their hash and app ID.

Both main and isolated builds use the native listener. Phone Firebase packages,
Google Services plugin application and Firebase manifest entries have been
removed. Neither build consumes `google-services.json` or needs provider
environment variables; ignored local configuration files are left untouched.

A fresh trial defaults to HTTPS loopback, **not the existing live Avodah server**.
Before pairing, use Settings to select the separately authorized isolated test
server's trusted private HTTPS URL, then follow the app's restart/reconnect
instructions. Do not connect the trial to production data. Provision synthetic
notifications and a separate pairing. No TLS-verification bypass or public
receiver is provided.

Run the current sync server on that isolated environment, using a consistent
private backup before any schema/data change. The only sender secret needed is
`AVODAH_NOTIFICATION_SEND_TOKEN`. Leave `AVODAH_FCM_PROJECT_ID` and
`GOOGLE_APPLICATION_CREDENTIALS` unset for this trial. Use the existing documented
`avo notify` command with random opaque IDs and synthetic title/body text.
The receipt's legacy `delivery` field describes **FCM only**; `not-configured`
is expected without FCM and does not mean native streaming failed or succeeded.
Neither a receipt nor a connected listener proves Android alert presentation.

On the authorized installed trial app, open Notifications and press
**Enable / reconnect alerts**. Grant Android notification permission and confirm
that the ongoing status notification shows listening and offers Stop. If the
server is Tailscale-only, Tailscale must remain connected for **alerts as well as
inbox access**. There is no independent public push route in this trial.

## Stream and recovery contract

`GET /api/notifications/events/stream[?after=<cursor>]` requires the existing
`X-Av-Node-Id` and `X-Av-Pair-Token` headers. No producer or query-string credential
can read the stream. HTTPS, the configured server origin and normal certificate
verification are required by the Android client; redirects are refused.

Responses use `text/event-stream` with bounded JSON `data:` lines:

```json
{"type":"checkpoint","cursor":12}
{"type":"notification","cursor":13,"id":"opaque-notification-id"}
```

No title, body, remarks, token or external navigation URL is streamed. An initial
connection without `after` starts at the current checkpoint so enabling does not
announce the entire existing history. Reconnect uses its saved sequence and
replays missed new records. The reference is committed in the same transaction
as the inbox item, before signalling; duplicate producer retries do not append
another reference. Deletions suppress pending replay without losing other items.
The reference log persists across restart. Schema 2-to-3 migration preserves the
inbox/FCM outbox, takes a unique `.before-v3-<timestamp>` backup first, and does not
backfill historical records into a flood of alerts. Restoring an older server
history with a newer client cursor returns 409 and stops the listener for review,
not a silent cursor reset.

A connection lasts at most 50 seconds or 64 event references. Heartbeats occur
every 15 seconds and device authorization is rechecked before every batch and
heartbeat. Revocation closes the stream; native reception stops on authorization
failure. There is one active stream per paired node and at most 16 overall;
unauthorized/extra streams are rejected. Reconnect backs off from two seconds to
one minute on failures. Both server and client bound buffering and line sizes.
Proxy buffering must be disabled and upstream idle timeouts must permit the
stream; qualify the actual private route separately rather than changing a live
gateway during this trial.

Native replay state is scoped to a hash of server origin, node and pairing
identity. Credentials remain in memory, never URL parameters, service preferences
or logs. Generic alerts use stable tags; replayed sequences are skipped. A crash
between requesting an Android notification and committing its cursor may replace
an existing tagged alert, so external exactly-once presentation is not claimed.
Taps carry only the opaque ID and scope binding. Avodah rejects a different
server/pairing scope and fetches the exact record from the configured authenticated
origin before showing details. Opening/dismissing does not mark it read/handled.

## Required device trial, not yet performed

No ADB/device inspection, install, launch, battery setting change, Tailscale change
or live-server operation is authorized merely by this implementation.

1. Obtain device/test consent. Confirm exactly the intended USB phone, model and
   Android version without recording its serial. Verify APK hash, app ID, version,
   signing and recovery. Never uninstall, clear data or downgrade as a fallback.
2. Install only the exact isolated candidate, configure the isolated trusted
   route, pair it and enable the listener with Sinh. Test a synthetic manual send
   and an authorized agent send. Confirm generic notification text, exact-item
   taps and durable inbox records after dismissal or permission denial.
3. Disconnect USB. Leave the phone **unplugged, locked and idle beyond six hours,
   preferably overnight**. USB must not provide connectivity or keep it charging.
   Send synthetic events early and late. Record sender and actual Android alert
   timestamps separately, checking the alert before manually opening Avodah.
   A quick locked-screen pass is not overnight acceptance.
4. Test Wi-Fi/mobile switching, Tailscale off/on, server restart, process death,
   force-stop/reopen and reboot. No timely alert is expected while the private
   route is unavailable. Verify reconnect replay does not repeatedly announce
   the same event or duplicate the inbox record. Verify Stop and denied permission
   do not erase records. Record observed recovery instead of promising auto-start.
5. Retain only sanitized candidate hashes, phone model/OS, connection state,
   delay and battery observations. No serials, credentials, private messages or
   unrelated notifications. Agree acceptable delay/battery cost with Sinh.

If Android cannot sustain usable idle alerts under the agreed settings, stop
and report that result. Do not hide it with polling, exemptions or SDK downgrades.
Main-app native selection does not waive the remaining reliability checks or
authorize a fallback provider setup. Full Android/Linux inbox acceptance, private-route/security
qualification and human acceptance remain separate gates; a prototype connection
pass is insufficient.

References: [Android foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types),
[Android foreground-service timeouts](https://developer.android.com/develop/background-work/services/fgs/timeout),
[ntfy Android manifest](https://github.com/binwiederhier/ntfy-android/blob/main/app/src/main/AndroidManifest.xml).
