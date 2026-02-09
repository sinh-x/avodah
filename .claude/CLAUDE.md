# Avodah - Project Instructions for Claude

## Build Commands

**IMPORTANT**: This is a Flutter project. Always use `flutter` commands, NOT `dart` commands.

```bash
# ✅ CORRECT - Use these commands
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
flutter run

# ❌ WRONG - These will fail
dart pub get          # ERROR: Flutter SDK not available
dart run build_runner # ERROR: Flutter SDK not available
```

## Project Structure

- `lib/core/` - Core utilities (CRDT, storage, etc.)
- `lib/features/` - Feature modules (tasks, projects, tags, etc.)
- `test/` - Mirrors lib/ structure

## CRDT Document Pattern

When creating new CRDT documents, follow the existing pattern:

1. **Fields class** - Constants for field keys
2. **Document class** - Extends `CrdtDocument<T>`
3. **Model class** - Immutable UI model

Reference: `lib/features/tasks/models/task_document.dart`

## Testing

- Run all tests: `flutter test`
- Run specific test: `flutter test test/path/to/test.dart`
- Tests should cover: creation, fields, conversion, soft delete, CRDT merge

## Current Phase

Phase 2 (CRDT Foundation) complete. Phase 3 (Core Features) next.

## Scope (MVP)

- **Platform**: Linux/NixOS only
- **Integration**: Jira only (external credentials file)
- **Deferred**: GitHub, TaskRepeatCfg, Note, Android/iOS
