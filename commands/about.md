---
description: Show what the kokodudu plugin contains and its commands (read-only)
disable-model-invocation: true
---

Print the summary below as is. Change nothing, run no commands, edit no files.

## kokodudu plugin

Generic skills for everyday work. Every skill that changes something shows
its plan first and waits for an explicit yes.

| Command | What it does |
|---|---|
| `/kokodudu:commit [TASK-ID]` | Splits changes by topic, writes conventional commits `type(TASK-ID): subject` (subject max 72 chars, no co-author trailer), commits after approval. |
| `/kokodudu:pr [draft]` | Pushes the branch and opens a PR with the repository's own PR template, after approval. |
| `/kokodudu:polish-code [path or whole-file]` | Fixes style violations in changed code using the repo's style doc, formatter config or the bundled C# and Unity guide. Does not commit. |
| `/kokodudu:init` | Sets up GitNexus, CodeGraph, Caveman and MCP for Unity. GitNexus is then refreshed by the plugin's hook after every commit Claude makes. Needs approval. |
| `/kokodudu:about` | This summary. |

## Typical flow

1. `/kokodudu:polish-code` to clean the changed code.
2. `/kokodudu:commit` to commit it.
3. `/kokodudu:pr` to open the pull request.
