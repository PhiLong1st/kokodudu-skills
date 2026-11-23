# kokodudu skills

A Claude Code plugin that is also its own marketplace, built for Unity
projects. It ships five skills and three commands. Everything that changes files,
git history or your config shows its plan and waits for your approval first.

| Skill | Command | What it does |
|---|---|---|
| `task-feature` | `/kokodudu:task-feature <task-id or notion-url>` | Orchestrates a feature end to end: confirmed gates for branch, spec, review, Notion update, plan and decisions, then phased execution with dev and QA agents, one commit per step. Does not push or open a PR unless asked. |
| `commit` | `/kokodudu:commit` | Splits changes by topic and writes conventional commits (`type(TASK-ID): subject`, subject max 72 chars, no co-author trailer). |
| `pr` | `/kokodudu:pr` | Pushes the branch and opens a PR using the repository's own PR template. |
| `polish-code` | `/kokodudu:polish-code` | Fixes style violations in the changed code. Ships a bundled C# and Unity style guide. |
| `unity` | `/kokodudu:unity` | Drives the Unity Editor, Unity CLI first when it is installed, then [MCP for Unity](https://github.com/CoplayDev/unity-mcp): scenes, scripts, tests, console, screenshots. Claude can also load it on its own. |
| `unity-setup` (command) | `/kokodudu:unity-setup` | Prepares a Unity project: runs Claude's `/init` if there is no `CLAUDE.md`, adds the pinned Unity and OpenUPM packages, the UniTask and UniRx code rules, an `.editorconfig`, and a kokodudu workflow block in `CLAUDE.md` so the agent uses these skills along the project's own flow. Asks for approval, and separately for `manifest.json`. |
| `init` (command) | `/kokodudu:init` | Sets up GitNexus, CodeGraph and MCP for Unity (this repo), registers CodeGraph and Caveman with your Claude Code config, and checks that the GitHub CLI and git identity needed by `pr` and `commit` are ready. Asks for approval first, and separately for the one tracked-file edit. |
| `about` (command) | `/kokodudu:about` | Read-only summary of the plugin and its commands. Lives in `commands/`, not `skills/`. |

The five skills follow the Agent Skills specification: https://agentskills.io/home

## Layout

```text
kokodudu-skills/
├── .claude-plugin/
│   ├── plugin.json         # plugin name, version
│   └── marketplace.json    # marketplace name, plugin list
├── commands/
│   ├── about.md
│   ├── unity-setup.md
│   └── init.md
├── hooks/
│   ├── hooks.json          # PreToolUse and PostToolUse hooks on Bash
│   ├── guard-git.sh        # blocks --no-verify and staged secrets on git commit
│   └── refresh-index.sh    # refreshes GitNexus and CodeGraph after `git commit`
├── references/             # shared files, read by skills via ${CLAUDE_PLUGIN_ROOT}
│   ├── pr.txt              # fallback PR body template
│   ├── csharp-unity.md     # bundled C# and Unity style guide
│   ├── unity-code-rules.md # UniTask and UniRx rules for unity-setup
│   ├── unity-workflow.md   # kokodudu workflow block for unity-setup
│   └── .editorconfig
└── skills/
    ├── task-feature/SKILL.md
    ├── commit/SKILL.md
    ├── pr/SKILL.md
    ├── unity/SKILL.md
    └── polish-code/SKILL.md
```

## Install

From a local checkout:

```shell
/plugin marketplace add ~/Projects/kokodudu-skills
/plugin install kokodudu@kokodudu
```

From GitHub, once pushed:

```shell
/plugin marketplace add PhiLong1st/kokodudu-skills
/plugin install kokodudu@kokodudu
```

If the install summary says `Run /reload-plugins to activate.`, run it.

Try it without installing:

```bash
claude --plugin-dir ~/Projects/kokodudu-skills
```

## Update

`version` in `.claude-plugin/plugin.json` is the single source of truth.
Updates land only when it changes, so bump it on every release.

```shell
/plugin marketplace update kokodudu
/plugin update kokodudu
```

## Third-party plugins

The marketplace also lists two plugins referenced from their upstream repos.
Nothing is copied here, so they follow upstream.

| Plugin | Upstream | Install |
|---|---|---|
| `gitnexus` | `abhigyanpatwari/GitNexus`, path `gitnexus-claude-plugin` | `/plugin install gitnexus@kokodudu` |
| `notion-workspace-plugin` | `makenotion/claude-code-notion-plugin` (official Notion skills and MCP server) | `/plugin install notion-workspace-plugin@kokodudu` |

For Notion, sign in once through `/mcp` after installing, then paste a task or
doc link and Claude can read it. CodeGraph, Caveman and MCP for Unity are
not Claude plugins; `/kokodudu:init` sets them up instead.

## Hooks

`hooks/hooks.json` registers two hooks on `Bash`.

**`PreToolUse`, `hooks/guard-git.sh`**: a deterministic guard that does not rely
on the model remembering the rules. It blocks `git commit` and `git push` with
`--no-verify`, and blocks `git commit` while a secret-looking file is staged
(`.env`, private keys, keystores, credential files; `.env.example` is fine).
Files staged in the same command line as the commit are not visible to it, so
the `commit` skill stages in a separate call. Needs `jq`; without it the hook
does nothing.

**`PostToolUse`, `hooks/refresh-index.sh`**: after Claude runs
`git commit`, it refreshes the indexes in the background:
`gitnexus analyze --skip-agents-md` and `codegraph sync`. Each one runs only if
the repo already has its folder (`.gitnexus/`, `.codegraph/`), so run
`/kokodudu:init` once per repo first. It only sees commits Claude makes, not
commits from a terminal or IDE. Logs: `.gitnexus/post-commit.log` and
`.codegraph/post-commit.log`.

## Notes

- If you also keep copies in `~/.claude/skills/`, you will see both `/commit`
  and `/kokodudu:commit`. Delete the copies in `~/.claude/skills/` once the
  plugin is installed.
- A private GitHub repo is cloned with your own git credentials (SSH by
  default). `ssh -T git@github.com` must work and the key must be in
  `ssh-agent`.
