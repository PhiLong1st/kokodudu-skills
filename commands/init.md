---
description: Set up GitNexus, CodeGraph, Caveman and MCP for Unity for the current repo and Claude Code
allowed-tools: Read Edit Bash(gh release list *) Bash(git rev-parse *) Bash(git check-ignore *) Bash(command -v *) Bash(gitnexus *) Bash(codegraph *) Bash(caveman *) Bash(ls *) Bash(cat *) Bash(grep *)
disable-model-invocation: true
---

# init

Set up three code-intelligence tools. Flow: inspect read-only, show the plan,
wait for an explicit yes, act, verify, report. Make no change before the yes.

| Tool | Scope | What init does |
|---|---|---|
| GitNexus | this repo | First index (`.gitnexus/`). The plugin's hook then refreshes it after every `git commit` Claude makes. |
| CodeGraph | this repo + your Claude Code config | Registers the CodeGraph MCP server for Claude (global), then `codegraph init` creates `.codegraph/` and builds the index. The plugin's hook then runs `codegraph sync` after every `git commit` Claude makes. |
| Caveman | your Claude Code setup, all repos | Installs the output-compression hook and the recovery MCP server for Claude. |
| MCP for Unity ([CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp)) | this repo, Unity projects only | Adds the `com.coplaydev.unity-mcp` package to `Packages/manifest.json`, pinned to a release tag. |

A tool that is not installed is skipped with a note. Never install a tool for
the user: tell them how (for example `npm i -g gitnexus`) and move on.

MCP for Unity is the one item that edits a tracked file
(`Packages/manifest.json`), so it never runs on a general yes: it needs its own
explicit yes, named as such.

## 1. Inspect (read-only)

- Repo root: `git rev-parse --show-toplevel`. Not a git repo: do only the
  Caveman part, skip the two repo tools, and say so.
- For each of `gitnexus`, `codegraph`, `caveman`: `command -v <tool>`.
- Repo tools: does `<root>/.gitnexus/` exist? does `<root>/.codegraph/` exist?
  Is each ignored (`git check-ignore -q .gitnexus`, `git check-ignore -q
  .codegraph`)?
- CodeGraph MCP: is a `codegraph` server already in the Claude MCP config
  (`grep -l codegraph` on `~/.claude.json` and `~/.claude/settings.json`)?
  Already present: skip the registration. Find the agent id for Claude Code with
  `codegraph install --print-config claude` (it writes nothing). If `claude` is
  not a valid id, read the valid ids from the error and pick the Claude Code
  one; never guess, never use `--target auto` or `all`, which would also wire
  other editors.
- Caveman: is it already set up for Claude? Look for a caveman hook in
  `~/.claude/settings.json` and a `caveman` server in the Claude MCP config
  (`grep -l caveman` on those files). Already present: mark it done, skip it.
- MCP for Unity: is this a Unity project (`ProjectSettings/ProjectVersion.txt`
  exists)? Not Unity: skip. Does `Packages/manifest.json` already list
  `com.coplaydev.unity-mcp`? Then skip. Does it list a different Unity MCP
  package, or does the Claude MCP config already have a `unity-mcp` server? Then
  do not add this one: a second server under the same name would clash. Show
  what was found and ask. Is `uv` on PATH (`command -v uv`)? The server needs
  it: if missing, say so and tell the user to install it themselves.

## 2. Show the plan and ask

Show exactly what will run, then ask "OK to proceed?". Only a clear yes counts.
List each item with its scope, and mark the skipped ones and why:

1. GitNexus: `gitnexus analyze --skip-agents-md`. The flag keeps it from
   rewriting `CLAUDE.md` and `AGENTS.md`. If `.gitnexus/` already exists, offer
   it as a refresh.
2. CodeGraph, two parts, each skipped if already done:
   a. `codegraph install --target <claude id> --location global --yes`
      registers the MCP server for Claude Code only. Say plainly that this
      changes the user's global Claude Code config and that
      `codegraph uninstall` undoes it.
   b. `codegraph init -y` (non-interactive, takes the defaults) builds
      `.codegraph/` in this repo. Skip if `.codegraph/` exists already.
3. Caveman: `caveman hooks install claude` and `caveman mcp install claude`.
   Say plainly that these change the user's global Claude Code config, not only
   this repo, and that `caveman hooks uninstall claude` and
   `caveman mcp uninstall claude` undo them.
4. MCP for Unity: add one line to the `dependencies` of
   `Packages/manifest.json` (show the exact line and the git diff it will
   produce): `"com.coplaydev.unity-mcp":
   "https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#<tag>"`. Take
   `<tag>` from the latest release (`gh release list -R CoplayDev/unity-mcp
   --limit 1`), never `main`. Ask for this item as its own yes. It leaves
   `Packages/manifest.json` and `Packages/packages-lock.json` modified and
   uncommitted: say so. Unity must be reopened or refocused to resolve it, and
   the user then runs `Window > MCP for Unity > Configure All Detected Clients`
   inside Unity: tell them, do not try to do it.
5. For `.gitnexus` and `.codegraph` that are not ignored: they will show as
   untracked. Ask on its own whether to add them to `.git/info/exclude` (local,
   never committed).

State that nothing is committed, and that the only tracked file changed is
`Packages/manifest.json`, and only if MCP for Unity was approved. The user may
approve only some items: do exactly those.

## 3. Act

Only after the yes, run the approved items in the order above. The two indexers
can take a while on a big repo: run them in the background and do not wait on
them unless the user asked. Append to `.git/info/exclude` only if approved.

Never commit or push. Never touch a tracked file other than the one approved
line in `Packages/manifest.json`.

## 4. Verify

Run `gitnexus status`, `codegraph status` and `caveman status`, for the tools
that were set up. If one errors, show the error as is and do not claim that
tool works. A background index still running is "in progress", not a failure.
For MCP for Unity, re-read `Packages/manifest.json` and confirm the line is
there; whether Unity resolved the package cannot be checked from here.

## 5. Report

One short list: per tool, done, skipped (and why) or failed. Remind the user
that:

- the GitNexus and CodeGraph refresh hook only fires for commits Claude makes, not for commits made
  in a terminal or IDE;
- Caveman may need a new Claude Code session to take effect.
