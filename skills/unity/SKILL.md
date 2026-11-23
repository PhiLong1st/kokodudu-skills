---
name: unity
description: Drive the Unity Editor, Unity CLI first when it is installed, then MCP for Unity (CoplayDev/unity-mcp) - compile, tests, console, C# evaluation, scenes, GameObjects, scripts, assets and screenshots. Use when working in a Unity project and either the unity CLI or the unity-mcp tools / mcpforunity:// resources are available. Follows the Agent Skills specification, see https://agentskills.io/home
compatibility: Designed for Claude Code. Needs a Unity project with either the Unity CLI (preferred when installed) or the MCP for Unity package and a connected server (uv on PATH). MCP for Unity is set up with /kokodudu:init.
metadata:
  version: "1.0"
---

# Unity: CLI first, MCP for Unity second

## Pick the channel first

A mature command-line tool costs fewer tokens than an MCP round trip and works
against the same Editor, so check for it before using MCP.

1. If the project's `CLAUDE.md`, `AGENTS.md` or the kokodudu block names a
   channel for a job, follow it
2. Otherwise, if the Unity CLI exists (`command -v unity`, or
   `~/.unity/bin/unity`) and `unity status --project-path "$PWD" --format json`
   lists this project with `state: "ready"`, use the CLI for: status, recompile
   and compile errors, running tests, reading the console, evaluating C#.
   Always pass `--project-path "$PWD"` (or the worktree's path), and look up exact
   commands with `unity command --query <word>` and `unity command <group>
   <name> --help` instead of guessing
3. Use MCP for Unity for what the CLI has no command for: scene and GameObject
   edits, components, prefabs, assets, screenshots. The rest of this file is
   about that channel
4. Neither is available: say so and point to `/kokodudu:init`. Do not edit
   `Packages/manifest.json` from here

A CLI PlayMode run still needs the Editor focused, same as through MCP.

## MCP for Unity

Operating notes for the CoplayDev/unity-mcp tools. Tool names and parameters
change between releases: when unsure, read the tool's own schema or the upstream
docs (https://coplaydev.github.io/unity-mcp/reference/tools) instead of
guessing.

## Workflow: resources first, then tools, then verify

1. Read `mcpforunity://editor/state`. Proceed only when `ready_for_tools` is
   true. If `is_compiling` or `is_domain_reload_pending` is true, wait and read
   it again.
2. Understand the scene with resources and `find_gameobjects` (it returns ids;
   read details through the resource, not by guessing).
3. Act with the tool for the job (`manage_gameobject`, `manage_components`,
   `manage_scene`, `manage_asset`, `manage_prefabs`, `create_script`,
   `script_apply_edits`, `run_tests`, and so on).
4. Verify: `read_console` for errors and warnings, and a screenshot
   (`manage_camera` with `action="screenshot"`, `include_image=true`, a small
   `max_resolution`) when the result is visual.

## Rules that prevent the usual failures

- After `create_script` or `script_apply_edits`, Unity compiles on its own: do
  not call `refresh_unity`. Wait until `is_compiling` is false, read the console
  for errors, and only then attach the component.
- Group related work in `batch_execute` (also for several `find_gameobjects`).
  Keep a batch within the configured limit; use `fail_fast` when later steps
  depend on earlier ones.
- Page through large results: follow `next_cursor` until it is empty.
- Prefab instances are created with `manage_gameobject(action="create",
  prefab_path=...)`, not with `manage_prefabs`.
- Read `mcpforunity://project/info` before building UI, to see whether uGUI,
  TextMeshPro, Input System or UI Toolkit is present.
- Tests: `run_tests` starts a job, `get_test_job` polls it. Report only what the
  job returned.
- Several Editors open (for example one per worktree): list them first
  (`mcpforunity://instances`, `unity_instances` in some clients, or `unity
  status`). Pass `unity_instance` (`Name@hash`) on every call instead of
  relying on `set_active_instance`, which is shared by everything using the
  same MCP session, including sub-agents. A call into one Editor queues behind
  the others

## A missing tool is not always a broken connection

Before troubleshooting the connection, check:

- Project custom tools (C# `[McpForUnityTool]`) may be listed under
  `mcpforunity://custom-tools` and run with `execute_custom_tool`.
- A tool group may be switched off: `manage_tools(action="list_groups")`, then
  `manage_tools(action="activate", group="...")`.

## Errors

| Symptom | Likely cause | Do this |
|---|---|---|
| Tools answer "busy" | Compilation or reload in progress | Wait; re-read `mcpforunity://editor/state` |
| `stale_file` | File changed since the last SHA | Fetch the SHA again with `get_sha`, retry |
| Connection lost | Domain reload | Wait a few seconds, check state, retry |
| Commands do nothing | Wrong Editor instance | Check the `unity_instance` you passed, or `set_active_instance` |

## Boundaries

- Changes made through the Editor are not commits. Show the user what changed
  (hierarchy, files) and leave committing to `/kokodudu:commit`.
- Match the project's own code style when writing scripts; `/kokodudu:polish-code`
  checks it afterwards.
- For the MCP channel this skill assumes MCP for Unity is already installed and
  connected. If it is not and the CLI is not available either, say so and point
  to `/kokodudu:init`; do not edit `Packages/manifest.json` from here.
