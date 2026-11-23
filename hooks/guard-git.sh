#!/bin/sh
# PreToolUse hook (matcher: Bash). Deterministic guard for git commands, so the
# rules do not depend on the model remembering them. The hook input JSON arrives
# on stdin. Exit 2 blocks the command and sends stderr back to Claude.
#
# It blocks:
#   - `git commit` or `git push` with --no-verify (skips the repo's own hooks)
#   - `git commit` while a secret-looking file is already staged (.env, private
#     keys, keystores, credential files). `.env.example` and `.env.sample` are
#     allowed. Files staged in the same command line (`git add x && git commit`)
#     are not visible yet; the commit skill stages in a separate call.
#
# Everything else passes silently. Needs jq; without it the hook does nothing.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

case "$cmd" in
  *"git commit"*|*"git push"*) ;;
  *) exit 0 ;;
esac

case "$cmd" in
  *--no-verify*)
    echo "kokodudu guard: --no-verify is blocked. Fix the failing hook instead of skipping it." >&2
    exit 2
    ;;
esac

case "$cmd" in
  *"git commit"*)
    root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
    secrets=$(git -C "$root" diff --cached --name-only 2>/dev/null |
      grep -E '(^|/)\.env(\.[^/]*)?$|\.(pem|p12|pfx|jks|keystore)$|(^|/)id_(rsa|ed25519|ecdsa)$|(^|/)credentials(\.json)?$' |
      grep -Ev '\.env\.(example|sample|template)$')
    if [ -n "$secrets" ]; then
      {
        echo "kokodudu guard: a secret-looking file is staged. Unstage it before committing:"
        echo "$secrets" | sed 's/^/  /'
        echo "If it was ever pushed, rotate the key, deleting the file is not enough."
      } >&2
      exit 2
    fi
    ;;
esac

exit 0
