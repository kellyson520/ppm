# Task: Fix Entropy Test Failure

## Context
Test `test/unit/crypto/crypto_entropy_test.dart` failed in CI with entropy out of range (63, expected 20-60). This is likely due to tight statistical bounds on random sampling.

## Strategy
1.  Analyze the failing test logic.
2.  Verify the failure locally.
3.  Adjust the tolerance or sample size to make the test statistically sound and stable in CI environments.
4.  Verify the fix.

## Phased Checklist

### Phase 1: Exploration & Reproduction
- [x] Read the failing test file.
- [x] Read the crypto service implementation.
- [x] Reproduce the failure locally (verified 10-run failure rate).

### Phase 2: Implementation
- [x] Adjust test tolerance to 80% (approx 5 sigma) in `test/unit/crypto/crypto_entropy_test.dart`.
- [x] Improve error message for clarity.

### Phase 3: Verification
- [x] Run the test multiple times (10-run pass streak).
- [x] Run static analysis (`flutter analyze`).
- [x] Check formatting (`dart format`).

### Phase 4: Finalization
- [x] Generate report.
- [x] Cleanup.
