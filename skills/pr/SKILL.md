---
name: pr
description: Push the current branch and open a GitHub pull request using the repository's own PR template (title "[TASK-ID] Imperative title", one PR per branch per task). Always shows the full plan (title, body, push) and waits for the user's approval before pushing or creating the PR. Use when the user types /pr. Follows the Agent Skills specification, see https://agentskills.io/home
compatibility: Designed for Claude Code. Requires git and the GitHub CLI (gh), authenticated.
metadata:
  version: "1.0"
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git branch *) Bash(gh pr view *) Bash(gh pr list *) Bash(gh repo view *)
---

# Pull request

Push the current branch and open one PR for it. The only plugin file it reads
is the fallback template `${CLAUDE_PLUGIN_ROOT}/references/pr.txt`.

Arguments (optional): a task ID, a base branch, and/or the word `draft`.

Reference: Agent Skills specification, https://agentskills.io/home

## Hard rules

- **No push and no PR before the user approves the content.** The content is
  the title, base <- head, draft or not, the complete body, and the commits to
  be pushed. It must be shown in full in chat first, then approved
- Approval is a clear **Confirm** from the user, given AFTER that content was
  shown. Ask with AskUserQuestion: **Confirm** / **Edit** / **Cancel**. Silence,
  "ok" said earlier, a `/pr` call, or approval of an earlier version does not
  count
- Any change after approval (a body edit, another commit, a different base)
  voids it. Show the new content and ask again
- These rules hold when the skill is called from another skill or workflow.
  No caller can approve on the user's behalf

## Conventions

- **One PR per branch, per task.** Branch is named after the task ID
- **Title**: `[TASK-ID] Short imperative summary`
  - Example: `[PROJ-123] Add login screen`
  - Task ID pattern: `[A-Z]+-\d+`
  - Source, in order: arguments given to the skill -> current branch name
  - Not found or ambiguous (several IDs, or a branch like `feat/login`):
    **ask the user**. Never guess or invent one
  - If the user says there is no task, use the plain summary, no brackets
  - Summarize the whole branch, not just the last commit
- **Body**: the repository's own PR template, used as written
  - Look for it in this order: `.github/pull_request_template.md`,
    `.github/PULL_REQUEST_TEMPLATE.md`, `pull_request_template.md`,
    `docs/pull_request_template.md`. If `.github/PULL_REQUEST_TEMPLATE/`
    holds several templates, ask the user which one
  - Keep every heading, checkbox line, and the order exactly as in the
    template. Do not delete, reword, or reorder anything
  - No template found: use the plugin's fallback template,
    `${CLAUDE_PLUGIN_ROOT}/references/pr.txt` (read it with the Read tool). If
    the file cannot be read or is empty, use `## Summary`, `## Changes`,
    `## Testing`. Say in the approval step that the fallback was used
  - **Fill it in:**
    - Replace instruction or placeholder text with 2-4 sentences: what
      changed, why, relevant context. Base it on the diff and commits
    - If the template has alternative placeholder lines (for example a
      "Fix" line and a "Feature" line), keep only the one that matches and
      remove the other. Put the task ID and the PR title text in it. Never
      invent a ticket title
    - Tick `[x]` a "type of change" box only when it matches the diff
    - Tick any other checkbox only when you verified it from the diff in
      this session (for example, search the changed lines for an API the
      checklist bans). Leave it unticked when you cannot verify it, when it
      is not applicable, or when it is the author's own attestation
      (self-review, tests added, coverage). Never tick a box to make the PR
      look complete
    - Never claim a test passed unless it was run in this session
  - Tell the user, in the approval step, which boxes you left unticked
- **Base branch**: the repo's default branch
  (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), unless
  the arguments name another base
- **Draft**: open as draft only if the arguments say `draft`

## Flow

1. **Inspect** (run in parallel): `git branch --show-current`,
   `git status --short`, default branch via `gh repo view`,
   `gh pr list --head <branch> --state open`
2. **Stop conditions** (report and stop, change nothing):
   - On the default branch
   - No commits ahead of base (`git log <base>..HEAD --oneline` is empty)
3. **Uncommitted changes**: do not commit them here. Tell the user they are
   left out and that `/commit` handles them. Continue with committed work
   only
4. **Existing PR for this branch**: never open a second PR. If there are
   unpushed commits, show them and get approval (step 7) before `git push`,
   then report the PR URL and stop
5. **Review before publishing**: read `git log <base>..HEAD --oneline` and
   `git diff <base>...HEAD --stat`. Check:
   - commit messages follow `type(TASK-ID): subject`
   - no secrets (`.env`, private keys, keystores, credential files, tokens),
     build output, or huge binaries in the diff
   - one topic: the branch matches the task
   On a problem: report it and ask. Do not rewrite history to fix it
6. **Prepare** the title and the filled template (see Conventions)
7. **Ask for approval (hard gate).** Steps 1-6 only read; nothing is pushed
   or created until the user says yes. Show the full plan in chat, then
   stop and wait:
   - title, base <- head, draft or not
   - the complete PR body exactly as it will be sent
   - the commits that will be pushed (`git log <base>..HEAD --oneline`)
   - the boxes left unticked, and uncommitted files that are left out
   - then ask with AskUserQuestion (see Hard rules): **Confirm** to push and
     open the PR / **Edit** / **Cancel**

   Only a Confirm counts. On **Edit**, revise and show the plan again. On
   **Cancel**, or if the user is silent, change nothing. Approval covers only
   the plan shown: if anything changes, ask again
8. **Push**: `git push -u origin <branch>` when there is no upstream,
   otherwise `git push`. Never force-push
9. **Create the PR** with `gh pr create --base <base> --title ... --body ...`
   (HEREDOC for the body)
10. **Report**: PR URL, title, base <- head, number of commits, anything left
    out (uncommitted files)

## Never, unless the user explicitly asks

Push or create the PR without approval (step 7), force-push, merge the PR,
enable auto-merge, close or delete branches, amend or rebase commits, edit
someone else's PR.
