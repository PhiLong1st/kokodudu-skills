---
description: Set up GitNexus in the current repo - build the first index so the plugin's post-commit hook can keep it fresh
allowed-tools: Read Bash(git rev-parse *) Bash(git check-ignore *) Bash(command -v *) Bash(gitnexus *) Bash(ls *) Bash(cat *)
disable-model-invocation: true
---

# init

Set up GitNexus in the current repository. Flow: inspect read-only, show the
plan, wait for an explicit yes, act, verify, report. Make no change before the
yes.

The plugin ships a Claude Code hook (`hooks/hooks.json`) that refreshes the
index after every `git commit` Claude runs, but only in repos that already
have a `.gitnexus/` folder. This command creates that folder.

## 1. Inspect (read-only)

- Repo root: `git rev-parse --show-toplevel`. Not a git repo: stop and say so.
- `command -v gitnexus`. Missing: stop and tell the user to install it
  themselves (`npm i -g gitnexus`). Do not install it.
- Does `<root>/.gitnexus/` already exist (already indexed)?
- Is `.gitnexus` ignored: `git check-ignore -q .gitnexus`.

## 2. Show the plan and ask

Show exactly what will happen, then ask "OK to proceed?". Only a clear yes
counts. The plan lists:

1. Run `gitnexus analyze --skip-agents-md` to build the first index (offer it
   as a refresh if `.gitnexus/` already exists). `--skip-agents-md` keeps it
   from rewriting `CLAUDE.md` and `AGENTS.md`.
2. If `.gitnexus` is not ignored: say it will show up as untracked and ask
   whether to add `.gitnexus/` to `.git/info/exclude` (local, never
   committed). Do this only on a separate yes.

State plainly that nothing tracked is changed and nothing is committed.

## 3. Act

Only after the yes:

1. Run `gitnexus analyze --skip-agents-md`. It can take a while on a big repo:
   run it in the background and do not wait on it unless the user asked.
2. Append `.gitnexus/` to `.git/info/exclude` only if the user said yes to it.

Never commit, push, or touch any tracked file.

## 4. Verify

`gitnexus status` runs. If it errors, show the error as is and do not claim
the setup works.

## 5. Report

Say what was done, whether the first index finished or is still running, and
anything that failed or could not be verified. Remind the user that the hook
only fires for commits Claude makes, not for commits made in a terminal or IDE.
