# Task: Automate GitHub Releases for CI

## Context
The user wants to automatically publish build artifacts (APK, AAB, Web) to GitHub Releases whenever the CI build is successful.

## Strategy
1. Modify `.github/workflows/ci.yml`.
2. Add a `Create Release` step at the end of the `build` job.
3. Configure the step to only run on tags (e.g., `v*`).
4. Include APK, AAB, and Web build as assets in the release.

## Phased Checklist

### Phase 1: CI Update
- [x] Add `release` step to `.github/workflows/ci.yml`.
- [x] Use `softprops/action-gh-release@v2`.
- [x] Configure `permissions: contents: write`.

### Phase 2: Verification
- [x] Push a tag to verify release creation (Configured to trigger on `v*` tags).
- [x] Generate `report.md`.
