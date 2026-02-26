# Task: Upgrade Android SDK to 36

## Context
`sqflite_sqlcipher` requires `compileSdk` >= 36. Current configuration is at 35.

## Strategy
1. Update `android/app/build.gradle.kts`.
2. Update task documentation.
3. Verify file changes.

## Phased Checklist

### Phase 1: Implementation
- [x] Update `compileSdk` to 36 in `android/app/build.gradle.kts`.
- [x] Update `targetSdk` to 36 in `android/app/build.gradle.kts`.

### Phase 2: Finalization
- [x] Update version in `pubspec.yaml`.
- [x] Update `CHANGELOG.md`.
- [x] Push to repository.
