---
description: Set up a Unity project for Claude Code with the kokodudu skills - CLAUDE.md, packages, code rules, .editorconfig and the kokodudu workflow
allowed-tools: Read Edit Write Skill(init) Bash(git rev-parse *) Bash(git branch *) Bash(git status *) Bash(git remote get-url *) Bash(git check-ignore *) Bash(ls *) Bash(cat *) Bash(grep *) Bash(cp *) Bash(command -v *)
disable-model-invocation: true
---

# unity-setup

Prepare the current Unity project so that Claude works in it with the kokodudu
skills, following the project's own code flow. Flow: inspect read-only, show the
plan, wait for an explicit yes, act, verify, report. Make no change before the
yes.

The shared files this command copies from live in the plugin:
`${CLAUDE_PLUGIN_ROOT}/references/` (`unity-code-rules.md`,
`unity-workflow.md`, `.editorconfig`).

| Item | What it does |
|---|---|
| CLAUDE.md | Runs Claude Code's own `/init` when the project has no `CLAUDE.md`. |
| Packages | Adds the Unity packages and the OpenUPM scoped registry below to `Packages/manifest.json`, pinned to the versions of the reference project. |
| Code rules | Appends the UniTask and UniRx rules to `CLAUDE.md` when those packages are present and the rules are not. |
| .editorconfig | Copies the plugin's `.editorconfig` when the project has none. |
| Workflow block | Writes the kokodudu workflow block into `CLAUDE.md` (between `<!-- kokodudu:start -->` and `<!-- kokodudu:end -->`) so the agent uses the kokodudu skills along the project's own flow. |
| Invariants | Proposes a short "Invariants" section for `CLAUDE.md` (what must stay true: architecture rules, boundaries, non-negotiables) built from the project's own docs, plus optional `CLAUDE.md` files for subfolders such as the tests. Written only after the user confirms the exact text. |
| Plugins and init | Tells the user the `/plugin` and `/kokodudu:init` commands to run. Check only. |

Packages (all pinned, none installed unless missing):

| Package | Version | Registry |
|---|---|---|
| `com.cysharp.unitask` | 2.5.10 | OpenUPM |
| `com.neuecc.unirx` | 7.1.0 | OpenUPM |
| `jp.hadashikick.vcontainer` | 1.17.0 | OpenUPM |
| `com.kyrylokuzyk.primetween` | 1.3.3 | OpenUPM |
| `com.unity.addressables` | 2.9.1 | Unity |
| `com.unity.inputsystem` | 1.19.0 | Unity |
| `com.unity.render-pipelines.universal` | 17.3.0 | Unity |
| `com.unity.test-framework` | 1.6.0 | Unity |

OpenUPM scoped registry: name `OpenUPM`, url `https://package.openupm.com`,
scopes `com.cysharp.unitask`, `com.kyrylokuzyk`, `com.neuecc.unirx`,
`jp.hadashikick.vcontainer`.

Editing `Packages/manifest.json` and `CLAUDE.md` changes tracked files, so the
package edit needs its own explicit yes, named as such. The MCP for Unity
package is not handled here: `/kokodudu:init` adds it.

## 1. Inspect (read-only)

- Unity project: `ProjectSettings/ProjectVersion.txt` exists. If not, say so
  and stop. Report the Editor version
- Repo root: `git rev-parse --show-toplevel`. Not a git repo: warn, continue
- `Packages/manifest.json`: which of the packages above are present (any
  version), which are missing; does the `OpenUPM` scoped registry exist, and
  which of its scopes are missing. A package present with a **different**
  version is left alone and listed, never changed
- `CLAUDE.md` and `AGENTS.md`: exist? Does `CLAUDE.md` already contain a
  kokodudu block (`<!-- kokodudu:start -->`)? UniTask or UniRx rules already
  (`grep -n "UniTask\|UniRx"`)?
- `.editorconfig` at the repo root: exists?
- **Project flow** (to fill the workflow block), found only from what exists:
  - base branch: `dev` if `git branch -a` lists it, else the default branch;
    say which and why
  - compile check and test commands: read them from `CLAUDE.md`, `AGENTS.md`,
    `README.md`, `docs/` and scripts (for example `Tools/`). Typical sources:
    a Unity CLI (`unity recompile`, `unity command test run`), a compile script,
    a test hook. Record the command exactly as the project writes it, with the
    file it came from. Not found: leave it out
  - **editor-less compile check**: a command that builds without opening Unity
    (for example `dotnet build` driven by a script under `Tools/`). Record it on
    its own line, because parallel agents in worktrees rely on it. Not found:
    leave it out
  - other rules the project states for agents (for example GitNexus
    impact-analysis rules): do not copy them, the block only points at them
- **Invariants**: does `CLAUDE.md` already have a section about architecture
  rules, boundaries or non-negotiables? Read what states them: `docs/`
  (architecture, design, guides), the assembly layout (`*.asmdef` names and
  their references), `README.md`. Collect only rules the sources actually state
  (for example "feature code does not reference the editor assembly"), each with
  its source file. Which subfolders have their own conventions that differ from
  the rest (for example the tests folder)?
- Plugins: is the `kokodudu` marketplace known? Check
  `~/.claude/plugins/known_marketplaces.json` and
  `~/.claude/settings.json` (`grep -l kokodudu`). Are `.gitnexus/` and
  `.codegraph/` present (a sign that `/kokodudu:init` was run)?

## 2. Show the plan and ask

Show exactly what will change, mark each item done, skipped (and why) or to do:

1. **CLAUDE.md**: run `/init` through the Skill tool, only if `CLAUDE.md` does
   not exist. If it exists, skip
2. **Packages** (own yes): the exact lines to add to `dependencies`, the exact
   `scopedRegistries` entry or the scopes to add, and the git diff they
   produce. List packages skipped because they are present, and those present
   with another version (not changed). Say that Unity must be refocused to
   resolve them, and that `Packages/packages-lock.json` will change
3. **Code rules**: append `${CLAUDE_PLUGIN_ROOT}/references/unity-code-rules.md`
   to `CLAUDE.md`. Only if UniTask or UniRx is in the manifest (already, or
   approved in item 2) and the rules are not in the file
4. **.editorconfig**: copy `${CLAUDE_PLUGIN_ROOT}/references/.editorconfig` to
   the repo root. Skip if one exists
5. **Workflow block**: show the full block, with the project flow filled in
   from step 1 (a line with no known value is removed, never invented), and
   say whether it is added at the end of `CLAUDE.md` or replaces the existing
   kokodudu block. The block never changes anything outside its markers
6. **Invariants** (own question): show the exact text of the proposed section,
   3 to 8 short lines, each ending with its source in parentheses. Only rules
   the project's own files state; never invent one, and say when fewer than 3
   were found. Mark each as "stated" or "inferred from the asmdef layout". Also
   show, if worth it, the exact text for a subfolder `CLAUDE.md` (for example
   `Assets/Scripts/Tests/CLAUDE.md`). Skip the item when `CLAUDE.md` already has
   such a section. The user can remove or edit lines before confirming
7. **Plugins and init** (check only, nothing changes): the commands for the
   user to run themselves, for what is missing:
   `/plugin marketplace add <path or repo of kokodudu-skills>`,
   `/plugin install kokodudu@kokodudu`, `/plugin install gitnexus@kokodudu`,
   `/plugin install notion-workspace-plugin@kokodudu`, and `/kokodudu:init`
   (GitNexus, CodeGraph, Caveman, the MCP for Unity package, the `gh` and git
   identity check)

State that nothing is committed. Ask with AskUserQuestion: **Confirm** for
items 1, 3, 4, 5, a separate question for item 2, and another for item 6
(each **Confirm** / **Skip** / **Cancel**). The user may approve only some items: do exactly those. Only a
Confirm counts.

## 3. Act

Only after the yes, in the order above.

- Packages: edit `Packages/manifest.json` with the Edit tool, keeping its
  existing formatting and key order; add dependencies without touching the
  existing ones, then the scoped registry (or only the missing scopes). The
  result must stay valid JSON
- Append to `CLAUDE.md` with Edit or Write; never rewrite or reorder what is
  already there. A replaced kokodudu block keeps everything outside its markers
- Invariants: append the confirmed section to `CLAUDE.md` exactly as shown. A
  subfolder `CLAUDE.md` is created only if it does not exist and was confirmed
- Never commit or push. Never change a package version that already exists

## 4. Verify

- Re-read `Packages/manifest.json`: every approved line is there, commas and
  braces are balanced, nothing else changed (`git diff` on the file shows only
  the approved lines)
- Re-read the kokodudu block in `CLAUDE.md`: markers present once, project flow
  as shown to the user
- `.editorconfig` exists if it was approved
- Whether Unity resolved the packages cannot be checked from here

## 5. Report

One short list: per item, done, skipped (and why) or failed. Then:

- files changed and not committed: `Packages/manifest.json`,
  `Packages/packages-lock.json` (after Unity resolves), `CLAUDE.md`,
  `.editorconfig`
- reopen or refocus Unity, then check the Package Manager
- the commands from item 6 that are still to run
- how to check the workflow: ask Claude for a small change and see that it uses
  `polish-code` and `commit` and waits for a Confirm. This command cannot verify
  that the agent follows the block
