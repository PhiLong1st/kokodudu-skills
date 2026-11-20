# kokodudu skills

A Claude Code plugin that is also its own marketplace. It ships three generic
skills and two commands. Each one shows its plan and waits for your approval before it changes
anything.

| Skill | Command | What it does |
|---|---|---|
| `commit` | `/kokodudu:commit` | Splits changes by topic and writes conventional commits (`type(TASK-ID): subject`, subject max 72 chars, no co-author trailer). |
| `pr` | `/kokodudu:pr` | Pushes the branch and opens a PR using the repository's own PR template. |
| `polish-code` | `/kokodudu:polish-code` | Fixes style violations in the changed code. Ships a bundled C# and Unity style guide. |
| `init` (command) | `/kokodudu:init` | Sets up GitNexus, CodeGraph and MCP for Unity (this repo) and Caveman (your Claude Code config). Asks for approval first, and separately for the one tracked-file edit. |
| `about` (command) | `/kokodudu:about` | Read-only summary of the plugin and its commands. Lives in `commands/`, not `skills/`. |

All three follow the Agent Skills specification: https://agentskills.io/home

## Layout

```text
kokodudu-skills/
├── .claude-plugin/
│   ├── plugin.json         # plugin name, version
│   └── marketplace.json    # marketplace name, plugin list
├── commands/
│   ├── about.md
│   └── init.md
├── hooks/
│   ├── hooks.json          # PostToolUse hook on Bash
│   └── gitnexus-refresh.sh # refreshes GitNexus after `git commit`
└── skills/
    ├── commit/SKILL.md
    ├── pr/SKILL.md
    └── polish-code/
        ├── SKILL.md
        └── references/csharp-unity.md
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

The marketplace also lists `gitnexus`, referenced from its upstream repo
(`abhigyanpatwari/GitNexus`, path `gitnexus-claude-plugin`). Nothing is copied
here, so it follows upstream. Install it with
`/plugin install gitnexus@kokodudu`. CodeGraph, Caveman and MCP for Unity are
not Claude plugins; `/kokodudu:init` sets them up instead.

## Hook

`hooks/hooks.json` registers a `PostToolUse` hook on `Bash`. After Claude runs
`git commit`, it refreshes the GitNexus index in the background
(`gitnexus analyze --skip-agents-md`). It does nothing unless the repo already
has a `.gitnexus/` folder, so run `/kokodudu:init` once per repo first. It only
sees commits Claude makes, not commits from a terminal or IDE. Log:
`.gitnexus/post-commit.log`.

## Notes

- If you also keep copies in `~/.claude/skills/`, you will see both `/commit`
  and `/kokodudu:commit`. Delete the copies in `~/.claude/skills/` once the
  plugin is installed.
- A private GitHub repo is cloned with your own git credentials (SSH by
  default). `ssh -T git@github.com` must work and the key must be in
  `ssh-agent`.
