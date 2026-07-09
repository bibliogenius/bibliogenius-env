#!/bin/bash
# Clean Architecture layer violation checker for BiblioGenius
# Runs as a PostToolUse hook after Edit/Write operations.
# Provides feedback to Claude when violations are detected.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Only check Rust and Dart files
case "$FILE_PATH" in
  *.rs|*.dart) ;;
  *) exit 0 ;;
esac

VIOLATIONS=""

# ─── RUST RULES ───

# R2: Domain layer must have ZERO framework dependencies
if [[ "$FILE_PATH" == */src/domain/* ]]; then
  if grep -qE "^use (sea_orm|axum|reqwest)" "$FILE_PATH"; then
    VIOLATIONS+="RULE R2 VIOLATION: Domain layer file imports framework code.\\n"
    VIOLATIONS+="File: $FILE_PATH\\n"
    VIOLATIONS+="Domain (src/domain/) must contain ONLY traits, error enums, and pure types.\\n"
    VIOLATIONS+="Remove sea_orm/axum/reqwest imports and use pure Rust types.\\n\\n"
  fi
fi

# R1: New code in API handlers must not use SeaORM directly.
#
# Judged on the lines the diff ADDS, not on the file as a whole. The previous
# whole-file heuristic was wrong in both directions: a single `State<AppState>`
# anywhere silenced it forever (peer.rs, 191 direct SeaORM calls, never fired),
# while a handler signature edit in a legacy file fired without a line of SQL.
SEAORM_RE='(::Entity::(find|insert|update|delete)|\.(one|all|exec|count)\(&?db\))'

# Echo the lines a file's working-tree diff adds, prefixed by their line number.
# An untracked file counts as entirely added. Prints nothing when git is absent.
added_lines() {
  local file="$1" dir repo rel
  dir=$(dirname "$file")
  repo=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 1
  rel=${file#"$repo"/}

  if ! git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    grep -n '' -- "$file"
    return 0
  fi

  git -C "$repo" diff HEAD -U0 -- "$rel" 2>/dev/null | awk '
    /^@@/ {
      match($0, /\+[0-9]+/)
      line = substr($0, RSTART + 1, RLENGTH - 1)
      next
    }
    /^\+\+\+/ { next }
    /^\+/ { print line ":" substr($0, 2); line++ }
  '
}

if [[ "$FILE_PATH" == */src/api/* && "$FILE_PATH" != */api/frb.rs && "$FILE_PATH" != */api/mod.rs ]]; then
  ADDED=$(added_lines "$FILE_PATH")
  GIT_OK=$?

  if [ $GIT_OK -ne 0 ]; then
    # No git: fall back to flagging any direct SeaORM in the file at all.
    ADDED=$(grep -n '' -- "$FILE_PATH")
  fi

  # Tests legitimately drive SeaORM directly. They live at the end of the file by
  # convention, so ignore everything from the first `#[cfg(test)]` onwards.
  TEST_START=$(grep -n '#\[cfg(test)\]' "$FILE_PATH" | head -1 | cut -d: -f1)
  [ -z "$TEST_START" ] && TEST_START=999999

  OFFENDING=$(echo "$ADDED" \
    | grep -E "$SEAORM_RE" \
    | cut -d: -f1 \
    | awk -v cutoff="$TEST_START" '$1 < cutoff' \
    | head -5 | tr '\n' ' ')

  if [ -n "$OFFENDING" ]; then
    # A file listed in "Legacy Handlers Pending Migration" is allowed to keep its
    # existing SeaORM, but touched code should still migrate. An unlisted file is
    # a plain violation.
    ARCH_DOC="$(dirname "$0")/../../.agents/instructions/architecture.md"
    BASENAME="api/$(basename "$FILE_PATH")"
    if [ -f "$ARCH_DOC" ] && grep -qE "\`$BASENAME\`.*\| *Legacy" "$ARCH_DOC"; then
      VIOLATIONS+="RULE R1 NOTE: new direct SeaORM added to a legacy handler.\\n"
      VIOLATIONS+="File: $FILE_PATH (added lines: $OFFENDING)\\n"
      VIOLATIONS+="$BASENAME is pending migration, so existing SeaORM may stay, but code you\\n"
      VIOLATIONS+="touch should move to State<AppState> + repository traits (Strangler Fig).\\n\\n"
    else
      VIOLATIONS+="RULE R1 VIOLATION: API handler uses SeaORM directly.\\n"
      VIOLATIONS+="File: $FILE_PATH (added lines: $OFFENDING)\\n"
      VIOLATIONS+="$BASENAME is NOT in 'Legacy Handlers Pending Migration'. Delegate to a\\n"
      VIOLATIONS+="repository trait or a service, or list the file if it is genuinely legacy.\\n\\n"
    fi
  fi
fi

# R4: Infrastructure repos should implement domain traits
if [[ "$FILE_PATH" == */infrastructure/repositories/*.rs && "$FILE_PATH" != */repositories/mod.rs ]]; then
  if ! grep -q "impl.*Repository for" "$FILE_PATH"; then
    VIOLATIONS+="RULE R4 WARNING: Infrastructure repository does not implement a domain trait.\\n"
    VIOLATIONS+="File: $FILE_PATH\\n"
    VIOLATIONS+="Infrastructure repositories must implement traits from domain/repositories.rs.\\n\\n"
  fi
fi

# ─── FLUTTER RULES ───

# F1: Screens must not contain direct HTTP/dio calls
if [[ "$FILE_PATH" == */lib/screens/*.dart ]]; then
  if grep -qE "(import.*package:dio|import.*package:http/|http\.get|http\.post|dio\.)" "$FILE_PATH"; then
    VIOLATIONS+="RULE F1 VIOLATION: Screen contains direct HTTP imports/calls.\\n"
    VIOLATIONS+="File: $FILE_PATH\\n"
    VIOLATIONS+="Screens must access data only through repositories, providers, or services.\\n\\n"
  fi
fi

# F2: Check for hardcoded user-facing strings (heuristic)
if [[ "$FILE_PATH" == */lib/screens/*.dart || "$FILE_PATH" == */lib/widgets/*.dart ]]; then
  # Look for common patterns of hardcoded strings in UI
  if grep -qE "(SnackBar\(.*content:.*Text\('[A-Z]|AppBar\(.*title:.*Text\('[A-Z]|alertDialog.*title:.*Text\('[A-Z])" "$FILE_PATH"; then
    VIOLATIONS+="RULE i18n WARNING: Possible hardcoded user-facing strings detected.\\n"
    VIOLATIONS+="File: $FILE_PATH\\n"
    VIOLATIONS+="All user-facing text must use TranslationService.translate(context, 'key').\\n\\n"
  fi
fi

# ─── REPORT ───

if [ -n "$VIOLATIONS" ]; then
  # Provide feedback to Claude (non-blocking)
  ESCAPED=$(echo -e "$VIOLATIONS" | sed 's/"/\\"/g' | tr '\n' ' ')
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "ARCHITECTURE CHECK: Potential violations detected. Please review and fix before completing the task:\\n\\n${ESCAPED}"
  }
}
EOF
  exit 0
fi

exit 0
