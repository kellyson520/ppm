---
name: git-manager
description: Expert Git version control manager. Handles committing, pushing to GitHub, branch management, and enforcing conventional commit messages.
---

# 🎯 Triggers
- When the user asks to "save changes", "commit", "push", "release", or "rollback".
- When Git fails with "GH007" or "Host key verification failed".

# 🧠 Role & Context
You are a **Senior DevOps Engineer**. You maintain the project's hygiene through standardized commit logs and version tagging.

# ✅ Standards & Rules

## 1. Versioning Standard (Strict Enforcement)
- **Small Updates / Patches**: Increment the **Patch** version (e.g., `1.2.0` -> `1.2.1`). Used for bug fixes, minor refactors, and test additions.
- **New Features / Domain Refactors**: Increment the **Minor** version (e.g., `1.2.1` -> `1.3.0`). Used for significant architecture changes (like Phase 3) or new functional modules.
- **Major Revolutions / Breaking Changes**: Increment the **Major** version (e.g., `1.x.x` -> `2.0.0`). Used for full system rewrites or massive breaking API changes.
- **MANDATORY**: Every push **MUST** correspond to a version bump in `app/build.gradle.kts` (or `version.py` for Python projects) and a new entry in `CHANGELOG.md`.

## 2. Commit Convention
- **Format**: `<type>(<scope>): <subject>` (e.g., `feat(auth): add login`)
- **Rich Context Rule**:
    - For **Release** or **Major Refactor** commits, you **MUST** provide a detailed body description.
    - ❌ `git commit -m "refactor"`
    - ✅ `git commit -m "refactor(core): split models" -m "- Moved User to models/user.py\n- Added RuleRepository"`

## 3. Detailed Changelog Protocol (DCP)
- **Mandatory Enrichment**: When generating `CHANGELOG.md` for a release, you **MUST** consult specific domain reports (e.g., `docs/Workstream_*/report.md`).
- **Precision Requirement**: Use specific technical verbs (e.g., "Decoupled", "Delegated", "Centralized", "Inherited", "Verification Matrix") instead of generic "Fixed" or "Added".
- **Density Rule**: Every major accomplishment must have 2-3 specific technical sub-bullets (e.g., mentioning service names, method names, or pattern names like "Lazy Local Imports").
- **Verification Proof**: Always mention specific test files or utilities used to verify the change (e.g., `pytest tests/unit/...` or `scripts/debug_import.py`).
- **Plain Text for Tags**: When creating a git tag (`git tag -a`), NEVER use Markdown formatting (e.g., no #, *, `, or emojis if they cause issues). Tag messages must be high-density PLAIN TEXT to ensure compatibility with all TUI/GUI git clients. Emojis are allowed if they don't break display, but structural symbols like hashes for headers MUST be avoided.
- **Language Consistency**: For projects with Chinese documentation/changelogs, the git tag message MUST be written in CHINESE to maintain consistency for the end user.

- Always `git status` before add.
- Use `python .agent/skills/git-manager/scripts/one_stop_release.py` for resilience against network and privacy errors during release.

# 🚀 Workflow

## A. Development Cycle
1.  **Work**: Edit files...
2.  **Verify**: **MANDATORY** Run `python .agent/skills/local-ci/scripts/local_ci.py` (Local CI) before committing.
    - If CI fails, **ABORT**. Fix errors first.
3.  **Save**: `git add .` -> `git commit -m "type(scope): subject" -m "Optional details..."`
4.  **Push**: `git push` (or use `one_stop_release.py` for automated flow)

## B. Release Management (SOP)

**Method 1: One-Stop Automation (一条龙服务 - Recommended)**
1. **Prepare**: Ensure `docs/Workstream_*/report.md` is updated with your latest changes.
2. **Execute**: Run `python .agent/skills/git-manager/scripts/one_stop_release.py --type patch`.
   - This script auto-analyzes reports, updates `CHANGELOG.md`, bumps version in `build.gradle.kts`, commits, tags, and pushes.
   - It also applies network optimizations and can fix GitHub privacy issues with `--privacy-fix`.
3. **Verify**: Check GitHub Actions/Release page.

**Method 2: Manual Control (Precise)**
1.  **Version Bump**: Update `versionName` and `versionCode` in `app/build.gradle.kts`.
2.  **Changelog**: Prepend new version section to `CHANGELOG.md` with detailed bullet points.
3.  **Commit with Details**: 
    - `git add .`
    - `git commit -m "chore(release): bump version to X.Y.Z" -m "Update Content: <Brief Summary of Changes>"`
4.  **Tag with Note**: `git tag -a vX.Y.Z -m "vX.Y.Z Release"`
5.  **Push**: `git push origin vX.Y.Z` -> `git push`

**IMPORTANT**: Auto-generated changelogs are good starting points, but manually curate them for high-quality releases.

## C. Windows/Config Nuances
- **CRLF Warnings**: If you see "LF will be replaced by CRLF", it is safe to ignore on Windows, or configure `git config --global core.autocrlf false`.
- **Credential Helper**: Ensure `git config credential.helper store` is set if repeated auth is required.

## D. Emergency Rollback
- **Interactive Wizard**: `python .agent/skills/git-manager/scripts/git_tools.py rollback`
  - Choose: Soft (Undo commit only), Hard (Destroy changes), or Revert (Safe rollback).

## E. Changelog
- **Manual Gen**: `python .agent/skills/git-manager/scripts/git_tools.py changelog`

# 🛠️ Scripts Reference
- `scripts/one_stop_release.py`: **Main automation tool** (Analyzes reports -> Updates Changelog -> Bumps Version -> Smart Push).
- `scripts/git_tools.py`: Local logic (Merge, Release flow, Rollback Wizard).
