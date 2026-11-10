#!/bin/bash
# PreToolUse guard: blocks destructive or sensitive operations.
# Exit 2 = BLOCK the tool call. Exit 0 = allow.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ─── BASH COMMAND GUARDS ───
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Block force push.
  #
  # Two complementary checks. The regex catches "git push ... --force" (and
  # therefore --force-with-lease) wherever it appears in the text, even inside
  # a subshell or behind an absolute path. The parser below catches the forms
  # the regex cannot see: an option between `git` and `push` (`git -C dir`),
  # `-f` after the remote, a `+refspec`, `--mirror`, quoted words, nested
  # `bash -c`, and flags on a continued line. Only the git subcommand counts,
  # so a commit message that mentions a push is not one.
  # Cases: .claude/hooks/test-guard-destructive.sh
  # Rewriting a remote branch is left to a person, from their own terminal.
  BLOCK_FORCE='{"decision":"block","reason":"BLOCKED: force push is not allowed. Use a regular push or ask the user."}'

  if echo "$CMD" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f'; then
    echo "$BLOCK_FORCE"
    exit 2
  fi

  # A compound command may chain several invocations: judge each one.
  # Join backslash-newline continuations first, so a flag on the next line
  # stays in the same segment.
  CMD_JOINED=${CMD//$'\\\n'/ }
  while IFS= read -r SEGMENT; do
    # The word loop is slow on long commands: skip segments without git.
    [[ "$SEGMENT" == *git* ]] || continue
    read -ra WORDS <<< "$SEGMENT"
    GIT_SEEN=0; PUSH_AT=-1; SKIP=0; QUOTE=
    for i in "${!WORDS[@]}"; do
      # Reduce "(git", "$(git", "/usr/bin/git", "\"git" and the like to "git".
      W=${WORDS[$i]##*[\(\{\`/]}
      W=${W//[\"\']/}
      if [ "$SKIP" -eq 1 ]; then
        # The argument of a global option may span several words:
        # -C "my dir", -C 'my dir', -C my\ dir. Skip all of them.
        RAW=${WORDS[$i]}
        if [ -n "$QUOTE" ]; then
          [[ "$RAW" == *"$QUOTE" ]] && { QUOTE=; SKIP=0; }
          continue
        fi
        case "$RAW" in
          \"*\"|\'*\') SKIP=0 ;;
          \"*) QUOTE=\" ;;
          \'*) QUOTE=\' ;;
          *\\) ;;
          *) SKIP=0 ;;
        esac
        continue
      fi
      if [ "$GIT_SEEN" -eq 0 ]; then
        [ "$W" = "git" ] && GIT_SEEN=1
        continue
      fi
      # Only the git subcommand counts: skip global options, stop at any
      # other subcommand (so "git commit -m 'push -f'" is not a push).
      case "$W" in
        -C|-c|--git-dir|--work-tree|--namespace) SKIP=1 ;;
        -*) ;;
        push) PUSH_AT=$i; break ;;
        *) GIT_SEEN=0 ;;
      esac
    done
    [ "$PUSH_AT" -lt 0 ] && continue

    for ((i = PUSH_AT + 1; i < ${#WORDS[@]}; i++)); do
      W=${WORDS[$i]//[\"\']/}
      case "$W" in
        --force|--force=*|--force-with-lease|--force-with-lease=*|--mirror)
          echo "$BLOCK_FORCE"; exit 2 ;;
        -o|--push-option|--repo|--receive-pack|--exec) i=$((i + 1)) ;;
        --*) ;;
        -*f*|+*) echo "$BLOCK_FORCE"; exit 2 ;;
      esac
    done
  done < <(printf '%s\n' "$CMD_JOINED" | awk '{ gsub(/&&|\|\||;|\|/, "\n"); print }')

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
