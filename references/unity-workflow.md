<!-- kokodudu:start -->
# kokodudu workflow

This project uses the skills of the `kokodudu` plugin. Use them in this order,
and follow the project's own rules below inside each step.

| Situation | Use |
|---|---|
| A feature with a spec or a Notion link | `/kokodudu:task-feature` (the user types it). It runs the gates and calls the skills below itself |
| Working in the Unity Editor (scenes, scripts, console, tests, screenshots) | the `unity` skill, and the project's compile and test commands under "Project flow" |
| The code is ready | `polish-code` (style), then `commit` |
| Committing | the `commit` skill. It shows the messages and files and waits for an explicit Confirm. Never run `git commit` by hand |
| Opening a pull request | `/kokodudu:pr`, only when the user asks. Never push or open a PR without their Confirm |

## Rules for the agent

- Follow this file's other sections and `AGENTS.md`. They win over the defaults
  of any skill when they are stricter
- Before editing, read the code that will be touched. Before committing, run
  the project's compile check and the tests that cover the change, and report
  the real result
- Do not skip, weaken or delete tests to get a green run
- Do not commit straight to the base branch. Do not push, open a PR, or write to
  Notion without the user's Confirm

## Parallel agents and worktrees (only when a task needs them)

Default: one Unity Editor, one agent working in it. Use the rest only when a
task is split across agents (for example `task-feature`, size L).

- **Parallel dev agents**: only for pure C# logic, each in its own git
  worktree, and none of them needs an Editor. They check their work with the
  editor-less compile check listed under "Project flow" (if the project has
  one). Parallel work never touches scenes, prefabs, ScriptableObjects, `.meta`
  files or ProjectSettings
- **Tests**: run them in ONE Editor, in the main worktree, after the worktrees
  are merged. PlayMode needs the Editor focused, so two Editors can never run
  PlayMode at the same time
- **An Editor per worktree** (only if an agent really needs one): EditMode
  only. The worktree has no `Library`, so the first open reimports everything
  and takes a lot of disk. Local files git does not track (test hook, code
  indexes) are not in a new worktree: copy them if the project needs them.
  Check whether the machine's Unity license allows two Editors
- **Target the right Editor** and never rely on a shared "active instance":
  - Unity CLI: pass `--project-path <that worktree>` on every command
  - MCP for Unity: pass `unity_instance` (`Name@hash`) on every call. List the
    Editors first (`unity status`, or the `unity_instances` resource). A hash
    comes from the project path, so each worktree has its own
  - A call into one Editor queues behind the others. Do not retry a long
    command (import, test run, `execute_code`) before checking, because it may
    already have been applied

## Project flow

<!-- Filled by /kokodudu:unity-setup from what the project actually has. A line with no known value is left out, never invented. -->
{{PROJECT_FLOW}}
<!-- kokodudu:end -->
