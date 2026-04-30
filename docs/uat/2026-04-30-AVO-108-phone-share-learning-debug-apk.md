# AVO-108 Phone Share-to-Learning Debug APK UAT Notes

Date: 2026-04-30
Branch: `feature/AVO-108-share-learning-capture`
Commit: `9dec79aa9ae573beffc4cd301fa84224d2a7c526`

## Build

- Command: `cd phone && flutter build apk --debug`
- Result: passed
- APK: `phone/build/app/outputs/flutter-apk/app-debug.apk`
- APK size: `206804067 bytes`
- APK SHA-256: `f089d3c253c1753f63c7ee0374bd341ed51766caf1ae605f90c887a8d82d3bdc`
- Build timestamp: `2026-04-30 12:35:04 +0700`

## Device Availability

- Command: `cd phone && flutter devices`
- Result: no Android phone or emulator was available in this environment.
- Detected devices: Linux desktop and Chrome web only.
- Physical phone validation status: blocked for builder; requires Sinh UAT on an Android phone.

## Sinh UAT Handoff

Install the debug APK on the Android phone, then run TS1 through TS5 from `agent-teams/requirements/artifacts/2026-04-30-avodah-phone-share-learning-capture-uat.md`.

Suggested install command when the phone is connected with USB debugging enabled:

```bash
cd /home/sinh/git-repos/sinh-x/tools/avodah/phone
flutter install --debug
```

If installing the already-built APK directly:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Validation path:

1. Confirm the phone app is paired and PA board data loads.
2. Open a browser URL, for example `https://example.com/avo-108-share-test`.
3. Share the URL to Avodah.
4. Confirm Quick Capture opens with the URL populated.
5. Leave Project set to `learning`.
6. Tap Save Capture.
7. On desktop, run `opa board --project learning`.
8. Record the resulting `LM-*` ticket ID.
9. Record whether any sync error or pending/failed message appeared.
10. For failure feedback validation, temporarily make `/api/tickets` unreachable if practical, repeat the share/save flow, and confirm the app shows pending or failed sync feedback instead of implying ticket creation succeeded.

## UAT Fields To Record

- Shared URL source: not tested by builder; record during Sinh UAT.
- Resulting LM ticket ID: not tested by builder; record during Sinh UAT.
- Sync status/error: not tested by builder; record during Sinh UAT.
- AC1 partial: marked for Sinh UAT because no Android device was available here.
- AC3 partial: marked for Sinh UAT because no Android device was available here.
- AC5: debug APK produced; physical install/share validation blocked for builder and handed off to Sinh.
