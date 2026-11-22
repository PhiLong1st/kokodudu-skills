---
description: Show what the kokodudu plugin contains and its commands (read-only)
disable-model-invocation: true
---

Print the summary below as is. Change nothing, run no commands, edit no files.

## kokodudu plugin

Skills and setup for Unity projects. Every skill that changes something shows
its plan first and waits for an explicit yes.

| Command | What it does |
|---|---|
| `/kokodudu:task-feature <task-id or notion-url>` | Orchestrates a feature end to end: confirmed gates (branch, spec, review, Notion update, plan, decisions), then phased execution with dev and QA agents and one commit per step. Does not push or open a PR unless asked. |
| `/kokodudu:commit [TASK-ID]` | Splits changes by topic, writes conventional commits `type(TASK-ID): subject` (subject max 72 chars, no co-author trailer), commits after approval. |
| `/kokodudu:pr [draft]` | Pushes the branch and opens a PR with the repository's own PR template, after approval. |
| `/kokodudu:polish-code [path or whole-file]` | Fixes style violations in changed code using the repo's style doc, formatter config or the bundled C# and Unity guide. Does not commit. |
| `/kokodudu:unity` | Guide for driving the Unity Editor through MCP for Unity: scenes, scripts, tests, console, screenshots. |
| `/kokodudu:init` | Sets up GitNexus, CodeGraph, Caveman and MCP for Unity, and checks the GitHub CLI and git identity that pr and commit need. GitNexus and CodeGraph are then refreshed by the plugin's hook after every commit Claude makes. Needs approval. |
| `/kokodudu:about` | This summary. |

## Typical flow

1. `/kokodudu:task-feature <task-id or notion-url>` to build the feature (it commits as it goes).
2. `/kokodudu:polish-code` to clean the changed code.
3. `/kokodudu:commit` for any leftover changes.
4. `/kokodudu:pr` to open the pull request.
