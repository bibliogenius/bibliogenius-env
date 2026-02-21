#!/bin/bash
# PreToolUse guard for no-code contributors (PO, PM, designer...).
# Blocks modifications outside safe zones.
# Exit 2 = BLOCK the tool call. Exit 0 = allow.
#
# ACTIVATION: This hook is NOT active by default.
# The contributor must add it to their .claude/settings.local.json
# (see NO_CODE_ONBOARDING.md for instructions).

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only guard Write and Edit operations
if [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "Edit" ]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ─── SAFE ZONES ───

# Translation files (.po)
if echo "$FILE_PATH" | grep -qE '/assets/i18n/[^/]+\.po$'; then
  exit 0
fi

# Curated lists (.yml)
if echo "$FILE_PATH" | grep -qE '/assets/curated_lists/.*\.yml$'; then
  exit 0
fi

# Theme directory
if echo "$FILE_PATH" | grep -qE '/lib/themes/'; then
  exit 0
fi

# Design tokens (app_design.dart only)
if echo "$FILE_PATH" | grep -qE '/lib/theme/app_design\.dart$'; then
  exit 0
fi

# Allowed simple screens
if echo "$FILE_PATH" | grep -qE '/lib/screens/(help_screen|feedback_screen|splash_screen)\.dart$'; then
  exit 0
fi

# Simple widgets (will be checked for line count by Claude, but allow the path)
if echo "$FILE_PATH" | grep -qE '/lib/widgets/[^/]+\.dart$'; then
  # Block if the file is too large (> 300 lines)
  if [ -f "$FILE_PATH" ]; then
    LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
    if [ -n "$LINE_COUNT" ] && [ "$LINE_COUNT" -gt 300 ]; then
      echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Ce widget fait plus de 300 lignes ($LINE_COUNT lignes). Les modifications de widgets complexes necessitent un developpeur. Demande de l'aide a l'equipe.\"}"
      exit 2
    fi
  fi
  exit 0
fi

# Image assets
if echo "$FILE_PATH" | grep -qE '/assets/images/'; then
  exit 0
fi

# ─── BLOCKED: Everything else ───

# Provide specific messages for common forbidden zones
if echo "$FILE_PATH" | grep -qE '\.rs$'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Les fichiers Rust (.rs) font partie du moteur backend. Seuls les developpeurs peuvent les modifier.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/lib/models/'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Le dossier models/ contient le contrat d'interface avec Rust. Le modifier peut casser l'application.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/lib/services/'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Le dossier services/ contient la logique metier. Seuls les developpeurs peuvent le modifier.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/lib/providers/'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Le dossier providers/ gere l'etat de l'application. Seuls les developpeurs peuvent le modifier.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/lib/data/'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Le dossier data/ gere l'acces aux donnees. Seuls les developpeurs peuvent le modifier.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/lib/src/rust/'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Le dossier src/rust/ contient du code genere automatiquement (FFI). Il ne doit jamais etre modifie a la main.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/lib/config/|/lib/utils/'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Les dossiers config/ et utils/ contiennent de la configuration interne. Seuls les developpeurs peuvent les modifier.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '(pubspec\.yaml|Cargo\.toml)$'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Ce fichier gere les dependances du projet. Le modifier peut casser la compilation.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/\.claude/hooks/'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Les hooks Claude sont des gardes de securite. Ils ne doivent pas etre modifies.\"}"
  exit 2
fi

if echo "$FILE_PATH" | grep -qE '/\.claude/settings'; then
  echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Les fichiers de configuration Claude ne doivent pas etre modifies par les contributeurs no-code.\"}"
  exit 2
fi

# Generic block for anything not in safe zones
echo "{\"decision\":\"block\",\"reason\":\"BLOQUE : Ce fichier n'est pas dans les zones autorisees pour les contributeurs no-code. Consulte NO_CODE_ONBOARDING.md pour la liste des fichiers que tu peux modifier.\"}"
exit 2
