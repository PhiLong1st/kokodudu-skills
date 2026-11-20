#!/bin/sh
# PostToolUse hook (matcher: Bash). After Claude runs `git commit`, refresh
# the GitNexus index in the background. The hook input JSON arrives on stdin.
#
# Silent no-op unless all of these hold:
#   - the Bash command contains "git commit"
#   - the current directory is inside a git repo
#   - the repo already has a .gitnexus/ index (created by /kokodudu:init)
#   - the gitnexus CLI can be found
#
# --skip-agents-md keeps analyze from rewriting CLAUDE.md / AGENTS.md, which
# would leave the tree dirty right after the commit.

input=$(cat)
case "$input" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -d "$root/.gitnexus" ] || exit 0

if ! command -v gitnexus >/dev/null 2>&1; then
  for bin in "$HOME"/.nvm/versions/node/*/bin; do
    [ -x "$bin/gitnexus" ] && PATH="$bin:$PATH"
  done
fi
command -v gitnexus >/dev/null 2>&1 || exit 0

cd "$root" || exit 0
nohup gitnexus analyze --skip-agents-md >"$root/.gitnexus/post-commit.log" 2>&1 &
exit 0
