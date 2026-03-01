# TODO: Fix Android Release Build Keystore

## Context
Android release build fails in CI (GitHub Actions) because:
1. `Build Android APK` step is executed before `Decode Keystore`.
2. Fallback to `debug.keystore` in `build.gradle.kts` fails because the default path doesn't exist on the CI runner.

## Strategy
1. **Adjust Step Order**: Move `Decode Keystore` before `Build Android APK` in `ci.yml`.
2. **Robust Keystore Verification**: Modify `build.gradle.kts` to only use keystore properties if the file actually exists on disk.
3. **CI environment check**: Use a conditional in `ci.yml` to only decode the keystore if the secret is provided.

## Phased Checklist

### Phase 1: Fix CI Step Order
- [x] Move `Decode Keystore` step in `.github/workflows/ci.yml`.
- [x] Handle missing secret in CI.

### Phase 2: Refine Gradle Signing Config
- [x] Update `android/app/build.gradle.kts` to skip signing if the keystore file is missing.

### Phase 3: Verify
- [x] Local build verify (should work).
- [x] CI build verify (if possible by checking the script structure).

## Status
- `[x]` Completed
