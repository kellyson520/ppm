---
name: ci-report-reader
description: Download and analyze CI failure reports (format-check, flutter analyze, test results) from GitHub Actions artifacts, then produce precise SEARCH/REPLACE fixes
---

# CI Report Reader Skill

## Purpose
When CI fails, this skill downloads the generated `ci-reports` artifact from the latest failed GitHub Actions run, parses every error message, and produces targeted SEARCH/REPLACE edits to fix them. No guessing — every fix cites a specific line from the report.

## Prerequisites
- GitHub PAT with `repo` scope available in the shell environment
- `curl`, `python3` in PATH

## Procedure

### 1. Find the latest failed CI run
```bash
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/<owner>/<repo>/actions/runs?status=failure&per_page=1" \
  | python3 -c "import json,sys; runs=json.load(sys.stdin)['workflow_runs'];
  print(runs[0]['id'] if runs else 'none')"
```

### 2. Download the ci-reports artifact
Get the artifact download URL from the run's artifacts list:
```bash
RUN_ID=<run_id>
# List artifacts
ARTIFACT_URL=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/<owner>/<repo>/actions/runs/$RUN_ID/artifacts" \
  | python3 -c "import json,sys; arts=json.load(sys.stdin)['artifacts'];
  print([a['archive_download_url'] for a in arts if a['name']=='ci-reports'][0])")

# Download (follow redirect to get the zip)
curl -L -H "Authorization: token $GITHUB_TOKEN" "$ARTIFACT_URL" -o /tmp/ci-reports.zip
```

### 3. Extract and read each report
```bash
mkdir -p /tmp/ci-reports && cd /tmp/ci-reports
unzip -o /tmp/ci-reports.zip
```
Three files are produced:
- `format-report.txt` — `dart format` output + `git diff --stat`
- `analyze-report.txt` — `flutter analyze` errors/warnings
- `test-report.txt` — `flutter test` failures

### 4. Parse errors into a structured fix list
For each report file:
- **analyze-report.txt**: grep for `error •` and `warning •` lines; extract file:line:column:message
- **test-report.txt**: grep for `Expected:` / `Actual:` blocks and test names
- **format-report.txt**: look for `Changed` lines or git diff output showing changed files

### 5. Produce fixes
For each identified issue:
1. Read the target file around the error line
2. Create a SEARCH/REPLACE edit that fixes the exact issue
3. Cite the report line that justified the fix in a comment

### 6. Push fixes and re-check CI
After applying all fixes, push and wait for CI to re-run. If CI passes → done. If still failing → repeat from step 1.

## Notes
- Never guess at fixes — every SEARCH/REPLACE must correspond to a specific error in the report
- Fix one category at a time: format → analyze → tests (in that order)
- Reports are retained for 3 days in GitHub Actions artifacts
