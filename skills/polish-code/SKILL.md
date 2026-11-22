---
name: polish-code
description: Polish code against a coding style guide. Finds violations in the changed files, proposes the exact edits, and applies only what the user approves; risky changes are listed for a decision, never applied silently. Includes a bundled C# and Unity style guide. Use when the user types /polish-code. Follows the Agent Skills specification, see https://agentskills.io/home
compatibility: Designed for Claude Code. Requires git. Verification uses the project's own build, lint, or test command if one exists.
metadata:
  version: "1.0"
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git ls-files *)
---

# Polish code

Bring code in line with a style guide without changing what it does.
The only plugin file it reads is the bundled style guide
`${CLAUDE_PLUGIN_ROOT}/references/csharp-unity.md`.

Arguments (optional): file or directory paths to polish, `branch` or `staged`
to pick the scope, `whole-file` to check untouched lines too, and/or the path
of a style guide.

Reference: Agent Skills specification, https://agentskills.io/home

## Principles

- Behavior stays identical. A polish edit never changes what the code does
- Smallest diff that fixes the violation. No drive-by cleanup
- Only the lines in scope. Legacy code outside the change is left alone
- The user approves before any file is edited

## Style source

Use the first that exists, and say which one you used:

1. A path given in the arguments
2. A style guide in the repo: `CODING-STYLE*`, `STYLE*`, or a style section of
   `CONTRIBUTING*`, at the repo root or in `docs/`
3. The repo's formatter or linter config (for example `.editorconfig`)
4. The bundled guide `${CLAUDE_PLUGIN_ROOT}/references/csharp-unity.md`, when
   the files in scope are C#
5. Nothing found: **ask the user** which style to apply. Never invent rules

Read the whole style source before checking any code. Its rules are tagged
**[IDE]** (a tool can check them) or **[review]** (judgment, by hand).

## Scope

In order:

1. Paths given in the arguments
2. Otherwise the files changed on this branch against the default branch
   (`git diff --name-only <base>...HEAD`), plus uncommitted changes
   (`git status --short`)

Then narrow it:
- Keep only files the style source covers (by language or extension)
- Drop generated, vendored, third-party, and build-output files
- Check only lines the change touched (`git diff -U0`), unless the arguments
  say `whole-file`
- More than about 20 files: ask the user to narrow the scope

## Flow

1. **Resolve** the style source and the scope. Ask if either is unclear
2. **Read** the style source in full, then every file in scope
3. **Find violations.** For each one record: file, line, rule number or name,
   the current code, the fixed code
4. **Classify** each finding
   - **Safe**: mechanical and behavior-preserving. Formatting, import or
     using order, access modifiers, local-variable names, redundant default
     initializers, comment wording, braces
   - **Needs a decision**: anything that could change behavior or an
     external contract. Renaming public or serialized members, changes to
     saved data or file formats, removing statics or singletons, moving
     initialization, splitting or moving types, rules marked **[review]**
     that need judgment
5. **Ask for approval (hard gate).** Steps 1-4 only read; no file is edited
   until the user says yes. Show the plan in chat, then stop and wait:
   - the safe edits, grouped by file: `line | rule | before -> after`
   - the needs-a-decision items, each with the risk in one line
   - counts: files, safe edits, items needing a decision
   - end with a question, e.g. "OK to apply the safe edits?"

   Only a clear yes counts. The user may approve part of the plan ("only
   these files", "skip rule 5.5"): apply only that. If the user asks for
   changes, revise and show the plan again. If the user declines or is
   silent, change nothing. Needs-a-decision items are applied only when the
   user approves that item by name
6. **Apply** the approved edits with the smallest possible changes. Touch
   nothing else
7. **Verify**
   - Re-read each edited file and confirm every edit matches the plan
   - Run the project's own build, lint, or test command if one is known
     (from the README, a project instruction file, or a script in the repo).
     Do not invent a command
   - If nothing could be run, say "not verified by a build or test"
8. **Report**: files changed, edits applied by rule, items left for the user,
   verification result. Do not commit: point to `/commit` for that

## Never, unless the user explicitly asks

Edit before approval (step 5), change behavior, rename public or serialized
members, touch files outside the scope, touch generated or vendored code,
commit, push, rewrite history.
