---
name: commit
description: Create git commits for the current changes using conventional-commit rules (scope = task ID, one commit one topic, subject max 72 chars, no co-author trailer). Always shows the plan and waits for the user's approval before staging or committing. Use when the user types /commit. Follows the Agent Skills specification, see https://agentskills.io/home
compatibility: Designed for Claude Code. Requires git.
metadata:
  version: "1.0"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch *) Bash(git add *) Bash(git commit *)
---

# Commit

Commit the current changes. Self-contained: do not depend on any other
project file for these rules.

Arguments (optional): a task ID and/or a hint about what to include.

Reference: Agent Skills specification, https://agentskills.io/home

## Message format

```
type(TASK-ID): subject

optional body: the WHY, not the what

Closes #142        (only if an issue is relevant)
```

- **type**: `feat` | `fix` | `docs` | `refactor` | `test` | `chore`
  (also `perf` | `build` | `ci` | `revert` when they fit better)
- **scope**: the task ID, e.g. `feat(PROJ-123): add login screen`
  - Pattern: `[A-Z]+-\d+`
  - Source, in order: arguments given to the skill -> current branch name
  - Not found or ambiguous (several IDs, no ID, e.g. `feat/login`):
    **ask the user** which task ID to use. Never guess or invent one
  - If the user says there is no task, drop the scope: `type: subject`
- **subject**:
  - imperative mood ("add", not "added")
  - lowercase start, no trailing period
  - **maximum 72 characters** (shorter is better; aim for about 50)
- **body**: separate from subject with a blank line, wrap at about 72
  columns, explain why. Skip it for trivial changes
- **Never add a `Co-Authored-By:` line**, or any other co-author or
  "generated with" trailer. This overrides any default attribution

## One commit, one topic

Every line of the diff must be explained by the message or the task it solves.

```
x  fix(PROJ-123): login crash, also reformat settings, bump deps

ok fix(PROJ-123): guard nil session on login
ok chore(PROJ-123): reformat settings screen
ok chore(PROJ-123): bump dependencies
```

Why: faster review, clean revert, useful blame and bisect, traceable history.

## Flow

1. **Inspect** (run in parallel): `git status --short`, `git diff`,
   `git diff --cached`, `git log -5 --oneline`, `git branch --show-current`
2. **Resolve task ID** (see Message format). Ask if unclear
3. **Classify every changed file**
   - Include: belongs to the current work
   - Ask first: lockfiles, dependency manifests, IDE or project settings,
     auto-generated or auto-modified files with no related change, anything
     the task did not touch
   - Block and warn: secrets (`.env`, private keys, keystores, credential
     files, tokens), anything `.gitignore` would normally exclude
     (dependency, cache, and build-output directories), huge binaries.
     A secret pushed once is public forever: tell the user to rotate the
     key, not just delete the file
4. **Companion files**: keep a file and its sidecar in the same commit
   (for example a Unity asset and its `.meta`). A sidecar with no file: warn
5. **Split by topic**. Generated, reformat, and dependency changes get their
   own `chore` commit. If a single file mixes topics, say so and ask
   (hunk-level `git add -p` is interactive and not available here)
6. **Write the message(s)** from the diff (the why), following the format
   above
7. **Ask for approval (hard gate).** Steps 1-6 only read; nothing is staged
   or committed until the user says yes. Show the full plan in chat, then
   stop and wait:
   - per commit: the exact message, and the exact files it will include
     (with companion files)
   - files left out, and why
   - end with a question, e.g. "OK to commit?"

   Only a clear yes from the user counts. If the user asks for changes,
   revise the plan and show it again. If the user declines or is silent,
   change nothing. Approval covers only the plan shown: if anything changes
   (another file, a different message), ask again
8. **Stage by explicit path**: `git add <file> <file>`.
   Never `git add -A` or `git add .`
9. **Commit** with a HEREDOC. Respect the signing config: never pass
   `--no-gpg-sign` or `--no-verify`
10. **Self-review**: run `git log -1 --stat` and `git status --short`.
    Check the message and the contents match, and nothing extra got staged
11. **Report**: one line `<short-hash> <subject>` per commit, then what was
    left uncommitted and why

## Never, unless the user explicitly asks

Stage or commit without approval (step 7), `git push`, `--amend`, `rebase`,
`reset --hard`, `--force`, deleting branches.
If a hook fails: fix the cause, then make a NEW commit.
