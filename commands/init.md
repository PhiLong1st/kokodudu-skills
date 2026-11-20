---
description: Set up GitNexus in the current repo - first index plus a post-commit hook that refreshes it
allowed-tools: Read Write Bash(git rev-parse *) Bash(git check-ignore *) Bash(command -v *) Bash(gitnexus *) Bash(chmod +x *) Bash(test *) Bash(ls *) Bash(cat *)
disable-model-invocation: true
---

# init

Set up GitNexus in the current repository. Flow: inspect read-only, show the
plan, wait for an explicit yes, act, verify, report. Make no change before the
yes.

## 1. Inspect (read-only)

Collect, with no side effects:

- Repo root: `git rev-parse --show-toplevel`. Not a git repo: stop and say so.
- `command -v gitnexus`. Missing: stop and tell the user to install it
  themselves (`npm i -g gitnexus`). Do not install it.
- Does `<root>/.gitnexus/` exist (already indexed)?
- Is `.gitnexus` ignored: `git check-ignore -q .gitnexus`.
- Does `<root>/.git/hooks/post-commit` exist? If it exists and is not the hook
  below, it belongs to someone else: do not overwrite it. Show its content and
  ask whether to stop or to append the hook block to it.
- Use `git rev-parse --git-path hooks` for the hooks directory instead of
  assuming `.git/hooks` (worktrees, custom `core.hooksPath`).

## 2. Show the plan and ask

Show exactly what will happen, then ask "OK to proceed?". Only a clear yes
counts. The plan lists, each only when needed:

1. Run `gitnexus analyze --skip-agents-md` once to build the first index
   (skipped if `.gitnexus/` already exists; offer it anyway as a refresh).
   `--skip-agents-md` keeps it from rewriting `CLAUDE.md` and `AGENTS.md`.
2. Write the hook file `<hooks dir>/post-commit` with the content in the
   section "Hook content" and make it executable.
3. Add `.gitnexus/` to `.git/info/exclude` if it is not ignored yet. This file
   is local and never committed, so no tracked file changes.

State plainly that the hook lives in the local hooks directory, is never
tracked or shared, and runs the analyze step in the background after every
commit.

## 3. Act

Only after the yes, in this order:

1. Run the first `gitnexus analyze --skip-agents-md` (if in the plan). It can
   take a while on a big repo: run it in the background and do not wait on it
   unless the user asked.
2. Write the hook file with Write, then run `chmod +x` on it. If `chmod` is
   denied by the project's permission rules, do not look for a workaround:
   tell the user to run `chmod +x <path>` themselves.
3. Append `.gitnexus/` to `.git/info/exclude` (if in the plan).

Never commit, push, or touch any tracked file.

## 4. Verify

- `test -x <hooks dir>/post-commit` succeeds.
- `gitnexus status` runs. If it errors, show the error as is and do not claim
  the setup works.

## 5. Report

Say what was created and where, whether the first index finished or is still
running, and anything that failed or could not be verified. One short list.

## Hook content

Write this file as is:

```sh
#!/bin/sh
# Refresh the GitNexus index in the background after every commit.
# Local only: lives in the hooks dir, so it is never tracked or shared.
# --skip-agents-md keeps analyze from rewriting CLAUDE.md / AGENTS.md,
# which would leave the tree dirty right after the commit.

root=$(git rev-parse --show-toplevel) || exit 0
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
```
