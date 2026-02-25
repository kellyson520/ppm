# Task: Fix GitHub Release Automation

## Context
CI build completes successfully and artifacts are available in the CI run, but they are not being pushed to the GitHub Release page as expected.

## Strategy
1. Modify `.github/workflows/ci.yml`.
2. Remove `AAB` and `zip` archive steps to simplify the release.
3. Use glob patterns (`build/web/**/*`) in `softprops/action-gh-release@v2` to upload individual files.
4. Explicitly declare compilation tool versions (Java 17, Flutter 3.24.5, Android NDK r27) to ensure build consistency.
5. Ensure `GITHUB_TOKEN` is used for authentication.

## Phased Checklist

### Phase 1: Analysis & Diagnostic
- [x] Analyze `ci.yml` structure.
- [x] Verify authentication requirements.

### Phase 2: Configuration Update
- [x] Update `ci.yml` to upload individual assets instead of archives.
- [x] Remove `zip` archive steps for Web.
- [x] Remove `AAB` from release files.
- [x] Use glob patterns for Web build output (`build/web/**/*`).
- [x] Explicitly declare tool versions (Java 17, Flutter 3.24.5, NDK r27) in CI.

### Phase 3: Verification
- [ ] Instruct user to push a new version tag (e.g., `v0.2.5`) to trigger the flow.
- [ ] Monitor result.

## Status
- [ ] Active
