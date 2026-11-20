#!/bin/sh
# PostToolUse hook (matcher: Bash). After Claude runs `git commit`, refresh the
# GitNexus and CodeGraph indexes in the background. The hook input JSON arrives
# on stdin.
#
# Each tool is a silent no-op unless all of these hold:
#   - the Bash command contains "git commit"
#   - the current directory is inside a git repo
#   - the repo already has that tool's index folder (.gitnexus/ or .codegraph/,
#     created by /kokodudu:init)
#   - the tool's CLI can be found
#
# GitNexus runs with --skip-agents-md so it does not rewrite CLAUDE.md or
# AGENTS.md, which would leave the tree dirty right after the commit.

input=$(cat)
case "$input" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# Find a CLI: on PATH first, then in any nvm node version.
find_cli() {
  command -v "$1" >/dev/null 2>&1 && return 0
  for bin in "$HOME"/.nvm/versions/node/*/bin; do
    [ -x "$bin/$1" ] && PATH="$bin:$PATH"
  done
  command -v "$1" >/dev/null 2>&1
}

if [ -d "$root/.gitnexus" ] && find_cli gitnexus; then
  nohup gitnexus analyze --skip-agents-md >"$root/.gitnexus/post-commit.log" 2>&1 &
fi

if [ -d "$root/.codegraph" ] && find_cli codegraph; then
  nohup codegraph sync "$root" >"$root/.codegraph/post-commit.log" 2>&1 &
fi

exit 0
