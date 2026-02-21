#!/bin/bash
# Stop hook: generates a session recap when Claude Code exits.
# Writes a summary to .claude/session-logs/

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/session-logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="$LOG_DIR/$TIMESTAMP.md"

# Gather git changes since session likely started (last 2 hours of commits)
RECENT_COMMITS=$(cd "$PROJECT_DIR" && git log --oneline --since="2 hours ago" --all 2>/dev/null | head -20)
MODIFIED_FILES=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null)
STAGED_FILES=$(cd "$PROJECT_DIR" && git diff --cached --name-only 2>/dev/null)
UNSTAGED_CHANGES=$(cd "$PROJECT_DIR" && git diff --stat 2>/dev/null | tail -1)

# Also check submodules/sub-repos
RUST_COMMITS=""
FLUTTER_COMMITS=""
if [ -d "$PROJECT_DIR/bibliogenius" ]; then
  RUST_COMMITS=$(cd "$PROJECT_DIR/bibliogenius" && git log --oneline --since="2 hours ago" 2>/dev/null | head -10)
fi
if [ -d "$PROJECT_DIR/bibliogenius-app" ]; then
  FLUTTER_COMMITS=$(cd "$PROJECT_DIR/bibliogenius-app" && git log --oneline --since="2 hours ago" 2>/dev/null | head -10)
fi

cat > "$LOG_FILE" <<EOF
# Session Recap — $TIMESTAMP

## Recent Commits (last 2h)
${RECENT_COMMITS:-_No commits in the last 2 hours._}

### Rust (bibliogenius)
${RUST_COMMITS:-_None_}

### Flutter (bibliogenius-app)
${FLUTTER_COMMITS:-_None_}

## Uncommitted Changes
### Modified (unstaged)
${MODIFIED_FILES:-_None_}

### Staged
${STAGED_FILES:-_None_}

### Stats
${UNSTAGED_CHANGES:-_No changes_}
EOF

# Keep only last 30 session logs to avoid bloat
cd "$LOG_DIR" && ls -t *.md 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null

exit 0
