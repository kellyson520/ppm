---
name: git-guardrails
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset.
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When blocked, Claude sees a message telling it that it does not have authority to access these commands.

## Steps

### 1. Ask scope

Ask the user: install for **this project only** (`.claude/settings.json`) or **all projects** (`~/.claude/settings.json`)?

### 2. Create the hook script

Create `.claude/hooks/block-dangerous-git.sh` with:

```bash
#!/bin/bash
COMMAND="$1"

# Check for dangerous commands
if echo "$COMMAND" | grep -E "(git\s+push|git\s+reset\s+--hard|git\s+clean\s+-f|git\s+branch\s+-D|git\s+(checkout|restore)\s+\.)" > /dev/null 2>&1; then
  echo "ERROR: This command is blocked by git-guardrails." >&2
  echo "Blocked: $COMMAND" >&2
  echo "If you need to execute this command, please do so manually in your terminal." >&2
  exit 2
fi

exit 0
```

Make it executable: `chmod +x .claude/hooks/block-dangerous-git.sh`

### 3. Add hook to settings

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. Verify

Test the hook:

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | .claude/hooks/block-dangerous-git.sh "git push origin main"
```

Should exit with code 2 and print a BLOCKED message to stderr.
