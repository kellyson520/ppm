# Task Report: CI Release Automation

## Summary
The CI workflow has been updated to automatically create a GitHub Release and upload build artifacts (APK, AAB, and Web zip) whenever a version tag (starting with `v`) is pushed to the repository.

## Changes
- Modified `.github/workflows/ci.yml`:
    - Added `contents: write` permissions to the `build` job.
    - Added a step to zip the Web build output.
    - Added a `Create Release and Upload Assets` step using `softprops/action-gh-release@v2`.
    - Configured the release step to run only on tags matching `refs/tags/v*`.

## Artifacts included in Release:
1. `app-release.apk` (Android APK)
2. `app-release.aab` (Android App Bundle)
3. `web-build.zip` (Web Build output)

## How to use:
When you are ready to release a new version, simply create and push a tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```
The CI will automatically build the project and create a Release named `v1.0.0` with all artifacts attached.

## Status
Completed.
