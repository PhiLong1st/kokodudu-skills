---
name: unity
description: Drive the Unity Editor through MCP for Unity (CoplayDev/unity-mcp) - scenes, GameObjects, C# scripts, assets, tests, console and screenshots. Use when working in a Unity project and the unity-mcp tools or mcpforunity:// resources are available. Follows the Agent Skills specification, see https://agentskills.io/home
compatibility: Designed for Claude Code. Needs a Unity project with the MCP for Unity package and a connected server (uv on PATH). Set up with /kokodudu:init.
metadata:
  version: "1.0"
---

# Unity through MCP for Unity

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
- Several Editors open: list them through `mcpforunity://instances` and pick one
  with `set_active_instance` before anything else.

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
| Commands do nothing | Wrong Editor instance | Check `set_active_instance` |

## Boundaries

- Changes made through the Editor are not commits. Show the user what changed
  (hierarchy, files) and leave committing to `/kokodudu:commit`.
- Match the project's own code style when writing scripts; `/kokodudu:polish-code`
  checks it afterwards.
- This skill assumes MCP for Unity is already installed and connected. If it is
  not, say so and point to `/kokodudu:init`; do not edit `Packages/manifest.json`
  from here.
