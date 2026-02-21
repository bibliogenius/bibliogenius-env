#!/bin/bash
# PreToolUse guard: blocks destructive or sensitive operations.
# Exit 2 = BLOCK the tool call. Exit 0 = allow.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ─── BASH COMMAND GUARDS ───
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Block force push
  if echo "$CMD" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f'; then
    echo '{"decision":"block","reason":"BLOCKED: force push is not allowed. Use a regular push or ask the user."}'
    exit 2
  fi

  # Block git reset --hard
  if echo "$CMD" | grep -qE 'git\s+reset\s+--hard'; then
    echo '{"decision":"block","reason":"BLOCKED: git reset --hard can destroy uncommitted work. Ask the user first."}'
    exit 2
  fi

  # Block git clean -f
  if echo "$CMD" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
    echo '{"decision":"block","reason":"BLOCKED: git clean -f deletes untracked files permanently. Ask the user first."}'
    exit 2
  fi

  # Block rm -rf on project root or broad paths
  if echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f?\s+(/|\.\.|\.\s|~/|"/)'; then
    echo '{"decision":"block","reason":"BLOCKED: recursive delete on a broad path. Be more specific or ask the user."}'
    exit 2
  fi

  # Block reading/catting credential files
  if echo "$CMD" | grep -qE '(cat|less|head|tail|more)\s+.*\.(env|pem|key|p12|keystore|jks)(\s|$)'; then
    echo '{"decision":"block","reason":"BLOCKED: reading credential/secret files via shell. Use a safer approach or ask the user."}'
    exit 2
  fi

  # Block dropping DB tables
  if echo "$CMD" | grep -qiE 'DROP\s+(TABLE|DATABASE)'; then
    echo '{"decision":"block","reason":"BLOCKED: DROP TABLE/DATABASE detected. Ask the user for confirmation."}'
    exit 2
  fi
fi

# ─── WRITE/EDIT GUARDS on critical files ───
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  BASENAME=$(basename "$FILE_PATH" 2>/dev/null)

  # Block overwriting credential files
  case "$BASENAME" in
    .env|.env.*|*.pem|*.key|*.p12|*.keystore|*.jks|credentials.json|service-account.json)
      echo "{\"decision\":\"block\",\"reason\":\"BLOCKED: writing to credential file '$BASENAME'. Ask the user first.\"}"
      exit 2
      ;;
  esac

  # Warn (but allow) on critical project files — use hookSpecificOutput for feedback
  case "$BASENAME" in
    Cargo.lock|pubspec.lock)
      cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "WARNING: You are modifying a lock file ($BASENAME). Lock files should normally be updated by package managers (cargo/flutter), not manually. Make sure this is intentional."
  }
}
EOF
      exit 0
      ;;
  esac
fi

# ─── DELETE GUARDS ───
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Block deletion of migration files
  if echo "$CMD" | grep -qE 'rm\s+.*migration'; then
    echo '{"decision":"block","reason":"BLOCKED: deleting migration files can break the database schema history. Ask the user first."}'
    exit 2
  fi
fi

exit 0
