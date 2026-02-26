# Task Report: Upgrade Android SDK to 36

## Overview
Upgraded Android build configuration to meet the requirements of `sqflite_sqlcipher` plugin, which now requires a minimum of `compileSdk` 36.

## Changes
- **File**: `android/app/build.gradle.kts`
  - `compileSdk` updated from 35 to 36.
  - `targetSdk` updated from 35 to 36.
- **File**: `pubspec.yaml`
  - Version bumped to `0.2.8+8`.
- **File**: `CHANGELOG.md`
  - Added entry for version 0.2.8.

## Verification Results
- Manual inspection of `android/app/build.gradle.kts` confirms the values are correctly set.
- Static analysis of the project infrastructure remains intact.

## Engineering Impact
- Ensures compatibility with latest SQLCipher plugins on Android.
- Prevents build failures in projects depending on higher SDK versions.
