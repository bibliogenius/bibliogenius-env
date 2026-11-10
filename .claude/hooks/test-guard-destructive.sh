#!/bin/bash
# Regression cases for guard-destructive.sh.
#
# Usage: bash .claude/hooks/test-guard-destructive.sh [path/to/hook]
# Prints one line per failing case and exits 1 if any fails.
#
# The cases live in this file on purpose: a command line that contains a
# forced push is blocked by the live hook itself, so run this script instead
# of pasting the cases into a shell.

HOOK=${1:-"$(dirname "$0")/guard-destructive.sh"}
PASS=0; FAIL=0

check() {
  local expected=$1 cmd=$2 code got
  code=$(jq -n --arg c "$cmd" '{tool_name: "Bash", tool_input: {command: $c}}' \
    | bash "$HOOK" >/dev/null 2>&1; echo $?)
  [ "$code" = 2 ] && got=block || got=allow
  if [ "$got" = "$expected" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL  expected %-5s got %-5s  %s\n' "$expected" "$got" "$cmd"
  fi
}
allow() { check allow "$1"; }
block() { check block "$1"; }

# ── Pushes that must go through ──
allow 'git push origin main'
allow 'git push -u origin fix/x'
allow 'git push -n origin fix/x'
allow 'git push origin main --tags'
allow 'git push --follow-tags origin main'
allow 'git push --no-verify origin fix/x'
allow 'git push --delete origin fix/x'
allow 'git push -o ci.skip origin fix/x'
allow 'git -C bibliogenius-app push upstream fix/x'
allow 'cd bibliogenius && git rebase upstream/main && git push origin fix/x'

# ── Not a push at all ──
allow 'git fetch upstream --force'
allow 'echo "remember to git push" && ls -f'
allow 'git commit -m "fix: never push + pull at once"'
allow 'git -C x commit -m "handle push -f"'
allow 'git log --grep push -F'

# ── Forced pushes the original regex already caught ──
block 'git push --force origin fix/x'
block 'git push -f origin fix/x'
block 'git push -fu origin fix/x'
block 'git push --force-with-lease origin fix/x'
block 'git push --force-with-lease=fix/x:abc123 origin fix/x'
block '(git push --force origin main)'
block '/usr/bin/git push --force origin main'
block 'echo $(git push --force origin main)'

# ── Forced pushes only the parser sees ──
block 'git -C bibliogenius push --force origin main'
block 'git -C bibliogenius push --force-with-lease origin fix/x'
block 'git -c push.default=current push -f'
block 'git --git-dir .git push -f origin main'
block 'git push origin fix/x -f'
block 'git push origin +fix/x'
block 'git push --mirror origin'
block '(git -C x push -f origin main)'
block '/usr/bin/git -C x push origin fix/x -f'
block 'cd x && git push origin fix/x; git push origin +main'

# ── Quotes, nested shells, line continuations ──
block 'bash -c "git -C x push -f origin main"'
block "sh -c 'git -C x push --force origin main'"
block 'git -C x push origin "+main"'
block "git -C x push origin '+main'"
block $'git -C x push origin main \\\n  --force'
block 'git -C "my dir" push -f origin main'
block "git -C 'my dir' push -f origin main"
block 'git -C my\ dir push -f origin main'
block 'git -C "a b c" push origin +main'
allow 'git -C "my dir" push origin main'
allow 'git -C "my dir" commit -m "push -f"'

# ── Other guards of this hook ──
block 'git reset --hard HEAD~1'
block 'git clean -fd'

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
