# Android Consolidation Plan

> **Status:** Superseded — root android/ removed; phone/ native builds obsoleted by AVO-038 web build (see AVO-039)

## Remove Root `android/` — Redirect to `phone/avodah_viewer`

> **Date:** 2026-03-13
> **Status:** Pending approval
> **Author:** Fred (analysis) + Sinh (decision)

---

## Background

Two Android build targets exist in this repo:

| | Root `android/` | `phone/android/` |
|--|--|--|
| **App name** | Avodah | Avodah Viewer |
| **Package** | `com.sinh_x.avodah` | `com.sinh_x.avodah_viewer` |
| **Version** | 0.4.2+7 | 0.1.0+1 |
| **Flutter SDK** | 3.38.9 | 3.41.2 |
| **Purpose** | Full task/timer app (no agent workflow) | Daily plan viewer + agent workflow review |
| **Built by** | `avo-build-android` / `avo-run-android` | Nothing (no flake command exists) |

The flake commands (`avo-build-android`, `avo-run-android`) currently point at the root — building the main app which has **no agent workflow features**. The `phone/avodah_viewer` has the agent workflow but no build command.

**Decision:** Remove the root Android build, redirect the flake commands to `phone/`.

---

## What Will Be Deleted

### `android/` — 25 files total

```
android/
├── .gitignore
├── avodah_android.iml               ← IDE metadata
├── build.gradle.kts                 ← Root Gradle config
├── gradle.properties
├── gradlew                          ← Gradle wrapper script
├── gradlew.bat
├── local.properties                 ← Auto-generated (Nix SDK paths) — already modified today
├── settings.gradle.kts
├── app/
│   ├── build.gradle.kts             ← compileSdk, ndkVersion, applicationId
│   └── src/
│       ├── debug/AndroidManifest.xml
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/io/flutter/plugins/GeneratedPluginRegistrant.java
│       │   ├── kotlin/com/sinh_x/avodah/MainActivity.kt
│       │   └── res/
│       │       ├── drawable/launch_background.xml
│       │       ├── drawable-v21/launch_background.xml
│       │       ├── mipmap-hdpi/ic_launcher.png
│       │       ├── mipmap-mdpi/ic_launcher.png
│       │       ├── mipmap-xhdpi/ic_launcher.png
│       │       ├── mipmap-xxhdpi/ic_launcher.png
│       │       ├── mipmap-xxxhdpi/ic_launcher.png
│       │       ├── values/styles.xml
│       │       └── values-night/styles.xml
│       └── profile/AndroidManifest.xml
├── build/
│   └── reports/problems/problems-report.html   ← Build artifact (not committed)
└── gradle/
    └── wrapper/
        ├── gradle-wrapper.jar
        └── gradle-wrapper.properties
```

**Nothing in `android/` is unique or irreplaceable.** It is a standard Flutter Android scaffold. `phone/android/` is structurally identical with different package naming.

---

## What Will Be Modified

### `flake.nix` — 2 lines changed

**Before:**
```nix
avo-run-android = pkgs.writeShellScriptBin "avo-run-android" "flutter run -d android";
avo-build-android = pkgs.writeShellScriptBin "avo-build-android" "flutter build apk --release";
```

**After:**
```nix
avo-run-android = pkgs.writeShellScriptBin "avo-run-android" "cd $(git rev-parse --show-toplevel)/phone && flutter run -d android";
avo-build-android = pkgs.writeShellScriptBin "avo-build-android" "cd $(git rev-parse --show-toplevel)/phone && flutter build apk --release";
```

### `flake.nix` — Android SDK: remove NDK + CMake

The `phone/avodah_viewer` has no native C/C++ dependencies (`sqlite3_flutter_libs` is only in the root pubspec). Its dependencies are pure Dart/Flutter: `web_socket_channel`, `shared_preferences`, `http`, `flutter_markdown`. **NDK and CMake are not needed** for the phone app.

**Before:**
```nix
includeNDK = true;
ndkVersions = [ "28.2.13676358" ];
cmakeVersions = [ "3.22.1" ];
```

**After:**
```nix
includeNDK = false;
```

This simplifies the Nix closure and avoids the NDK/CMake install failures that prompted today's debugging session.

Platform 36 is still needed — Flutter 3.41.2 (used by phone/) also requires `compileSdk 36`.

---

## What Is NOT Changed

| Item | Status | Why |
|------|--------|-----|
| `phone/` directory | Kept as-is | This becomes the canonical Android app |
| `phone/android/` | Kept as-is | The new Android build target |
| `lib/` (main app) | Kept as-is | Linux desktop + web builds unaffected |
| `linux/` | Kept as-is | Unrelated to Android |
| `web/` | Kept as-is | Unrelated to Android |
| `mcp/` | Kept as-is | CLI + server unaffected |
| Root `pubspec.yaml` | Kept as-is | No Android-specific entries; `sqlite3_flutter_libs` is a no-op on Linux |
| `flake.nix` Android SDK env vars | Kept as-is | `ANDROID_HOME`, `ANDROID_SDK_ROOT` still needed for phone/ builds |
| `flake.nix` platformVersions | Kept: `["36","35","34"]` | phone/ still needs platform 36 |

---

## Final Application Structure (After)

```
avodah/
│
├── lib/                        ← Main Avodah app (Linux desktop + Web)
│   └── features/
│       ├── tasks/
│       ├── timer/
│       ├── projects/
│       ├── tags/
│       └── settings/
│
├── phone/                      ← Android app (avodah_viewer) ← THE ANDROID APP
│   ├── android/                ← Only Android build directory in repo
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/             (deployment, review_item, snapshot, team_folder)
│   │   ├── screens/            (dashboard, review_queue, item_detail, deployment, team_browser)
│   │   ├── services/           (agent_api_client, sync_client, providers)
│   │   ├── settings/
│   │   └── widgets/
│   └── pubspec.yaml            (name: avodah_viewer, v0.1.0)
│
├── mcp/                        ← CLI (avo) + MCP server + sync server
│   ├── bin/
│   │   ├── avo.dart            ← CLI entry point
│   │   ├── server.dart         ← MCP server
│   │   └── sync_server.dart    ← WebSocket + HTTP API server
│   └── lib/services/
│       ├── agent_api_service.dart   ← HTTP endpoints for agent workflow
│       ├── markdown_parser.dart
│       └── registry_parser.dart
│
├── packages/avodah_core/       ← Shared CRDT + documents
├── linux/                      ← Linux desktop build target
├── web/                        ← Web build target
└── flake.nix                   ← Dev environment
```

### Build Commands (After)

| Command | Builds | Output |
|---------|--------|--------|
| `avo-build` | Linux desktop APK (`lib/`) | `build/linux/x64/release/bundle/avodah` |
| `avo-build-android` | Android APK (`phone/`) | `phone/build/app/outputs/apk/release/app-release.apk` |
| `avo-run` | Linux desktop (`lib/`) | Runs locally |
| `avo-run-android` | Android device (`phone/`) | Runs on connected device |
| `dart run mcp/bin/sync_server.dart` | Sync + HTTP API server | Serves WS + HTTP on :9847 |

---

## Risks & Considerations

| Risk | Impact | Notes |
|------|--------|-------|
| `phone/` version is 0.1.0 vs root's 0.4.2 | Low | Version strings are independent; phone app has its own versioning |
| `phone/android/local.properties` references old SDK hash | Low | Auto-regenerated on first build after `nix develop` |
| `phone/` uses Flutter 3.41.2 but flake may pin 3.38.9 | Med | Check `phone/pubspec.yaml` SDK constraint vs flake Flutter version |
| Root `pubspec.yaml` keeps `sqlite3_flutter_libs` | None | No-op on Linux; harmless to leave |
| `phone/` has no signing config for release builds | Low | Same situation as root — uses debug signing |
| Platform 36 still needed | None | Already added to flake |
| NDK removal may need flake re-enter | Low | `exit` + `nix develop` after flake change |

---

## Summary of Changes

| Action | Target | Type |
|--------|--------|------|
| **Delete** | `android/` (25 files) | Destructive — irreversible without git |
| **Modify** | `flake.nix` — 2 command lines | Redirect to `phone/` |
| **Modify** | `flake.nix` — remove `includeNDK`, `ndkVersions`, `cmakeVersions` | Simplify SDK |

**Total files deleted:** 25
**Total files modified:** 1 (`flake.nix`)
**Total files created:** 0
