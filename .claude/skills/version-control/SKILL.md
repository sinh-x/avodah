---
name: version-control
description: "Manage versioning for Avodah. Covers release strategy, branching, conventional commits, and version bumping. Use when the user wants to bump version, create a release, tag a version, update the changelog, or understand the release workflow. Triggers include: bump version, release, tag, changelog, version, semver."
---

# Version Control — Avodah

Manages semantic versioning across the project. CI owns the release process — agents should never manually bump versions unless CI is broken.

## Architecture

### Source of Truth

`packages/avodah_core/lib/version.dart` is the single source of truth:

```dart
const String version = 'X.Y.Z';
```

### Files Updated by `tool/bump_version.dart`

| # | File | What changes |
|---|------|-------------|
| 1 | `packages/avodah_core/lib/version.dart` | `version` constant |
| 2 | `pubspec.yaml` (root) | `version: X.Y.Z+N` |
| 3 | `packages/avodah_core/pubspec.yaml` | `version: X.Y.Z` |
| 4 | `mcp/pubspec.yaml` | `version: X.Y.Z` |
| 5 | `flake.nix` | `version = "X.Y.Z"` |
| 6 | `CHANGELOG.md` | New version section from git log |

### Version Exposed At

- `avo --version` — CLI flag
- MCP server — shared constant from `avodah_core`
- Flutter app — Settings screen

## Release Strategy (CI-Owned)

```
feat/* branch → PR to develop → accumulate → PR develop → main → CI auto-bumps → tag → GitHub Release
```

### How It Works

1. Work on feature branches off `develop`
2. Use conventional commit prefixes — these determine the bump type
3. Merge feature PRs to `develop`
4. When ready to release, merge `develop` → `main` via PR
5. CI automatically:
   - Detects bump type from commit messages since last tag
   - Runs `tool/bump_version.dart` (updates 6 files + CHANGELOG)
   - Resets build number to `+1`
   - Commits as `chore: bump version to X.Y.Z`
   - Tags `vX.Y.Z` and creates GitHub Release

### CI Skip Patterns

Commits starting with these prefixes are skipped by CI to prevent loops:
- `chore: bump version` — prevents release workflow re-trigger
- `chore(ci):` — prevents CI loops

### Manual Escape Hatch

Only use if CI is broken or for non-standard version jumps:

```bash
dart run tool/bump_version.dart patch|minor|major|X.Y.Z
```

### Build Number

`tool/bump_build.dart` increments the `+N` build number in root `pubspec.yaml`. Flutter builds only — not tied to releases. CI resets to `+1` on release.

### Develop Branch Version

The version on `develop` is informational only. CI auto-determines the next version on merge to `main` based on commit messages.

## Branching

| Branch | Purpose |
|--------|---------|
| `main` | Releases only — CI tags here |
| `develop` | Integration branch |
| `feat/*` | New features — branch from develop |
| `fix/*`, `bugfix/*` | Bug fixes — branch from develop |
| `perf/*` | Performance improvements — branch from develop |

## Conventional Commits

Follow `<type>(<scope>): <description>` format.

### Bump Type Mapping

| Prefix | Bump | Example |
|--------|------|---------|
| `fix:`, `fix(scope):` | **patch** | `fix: prevent task deletion with worklogs` |
| `chore:`, `refactor:`, `docs:`, `test:`, `ci:`, `perf:` | **patch** | `chore: update dependencies` |
| `feat:`, `feat(scope):` | **minor** | `feat: add GitHub sync` |
| `BREAKING CHANGE` in body, `feat!:`, `fix!:` | **major** | `feat!: new schema format` |

**Tip:** To stay on `0.3.x` patches, use `fix:` prefix — even for features that fill gaps in existing functionality.

## Semantic Versioning Policy

| Bump | When |
|------|------|
| **Patch** | Bug fixes, safety features, CLI polish, filling gaps in existing functionality |
| **Minor** | New capabilities (new integration, new major command) |
| **Major** | Breaking schema changes, API changes |
| **1.0.0** | Quality gate — daily-driver stable, schema settled, no critical bugs |

## Changelog Format

Uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) with sections auto-generated from git log:

- **Added** — new features (from `feat:` commits)
- **Fixed** — bug fixes (from `fix:` commits)
- **Changed** — everything else

## Roadmap

See `CHANGELOG.md` for the version roadmap table mapping versions to themes and issue numbers.
