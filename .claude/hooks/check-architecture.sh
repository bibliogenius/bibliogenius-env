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

# R1: New code in API handlers must not use SeaORM directly
# Check if the file was meaningfully modified (not just formatting)
if [[ "$FILE_PATH" == */src/api/* && "$FILE_PATH" != */api/frb.rs && "$FILE_PATH" != */api/mod.rs ]]; then
  # Check for SeaORM entity operations (the real violation signal)
  if grep -qE "(::Entity::find|::Entity::insert|::Entity::update|::Entity::delete|\.one\(&db\)|\.all\(&db\))" "$FILE_PATH"; then
    # Check if this file uses the OLD pattern (State<DatabaseConnection>) vs new (State<AppState>)
    if grep -q "State<DatabaseConnection>" "$FILE_PATH" && ! grep -q "State<.*AppState>" "$FILE_PATH"; then
      VIOLATIONS+="RULE R1 NOTE: Legacy handler still uses direct SeaORM.\\n"
      VIOLATIONS+="File: $FILE_PATH\\n"
      VIOLATIONS+="If you modified this handler, consider migrating touched code to use State<AppState> + repository traits.\\n"
      VIOLATIONS+="See CLAUDE.md 'Handler Migration Template' for the pattern.\\n\\n"
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
