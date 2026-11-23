# Task feature: execution

Part of the `task-feature` skill. Read after the Decision Sheet (or the S Sheet) is
confirmed. The invariant rules in `SKILL.md` apply to everything here.

## Loop per phase (sequential)

**A. Start**
- **QA** (1 agent, reused across all phases with SendMessage): writes the tests
  for the current phase, only in test files, commits with `kokodudu:commit`.
  Runs in parallel with dev
- **Dev**:
  - S: the orchestrator codes
  - M: 1 dev agent
  - L: 1-2 dev agents per the plan; agents running in parallel each work in
    their own worktree (`isolation: "worktree"`)

  Brief each agent fully: spec, the unit's plan, files it may edit, files it
  must not touch, commit rules, invariant rule 3, and the project rules it must
  follow (invariant rule 9). When done it reports back:
  the commits, the files changed, how it checked its work

**B. Orchestrator integrates**: review the diff against the plan and the
conventions (send back to dev to fix if needed), merge worktrees into the
feature branch, resolve conflicts, run `kokodudu:polish-code` on the changed
files (its fixes are their own commit), make sure it builds and compiles

**C. QA verifies**: run this phase's tests + every earlier phase's tests + the
existing suite. Use the project's own build and test commands (README, a
project instruction file, or a script); never invent one. Report per TC:
pass/fail, actual vs expected, logs, repro steps

**D. Fix loop**: on a failing test, pass QA's report to the right dev; dev
fixes and commits; orchestrator merges again; QA reruns

Fix the principle, not the example. Before patching, the dev states the root
cause in one or two lines and fixes that, not the failing input. Special-casing
the input is a breach of invariant rule 3. If the same class of failure comes
back in a second round, the orchestrator sends the dev back to look at the
sibling cases of the same cause and widen the fix, instead of patching one more
instance. Record each round (what failed, the cause, the fix) for the Lessons
step in Finish

**E. Phase gate**: move to the next phase only when QA reports all green.
Summarize the phase for the user in one paragraph (what was done, the commits,
the test results). No confirmation needed, keep going

## When you may stop

Stop and ask the user only in these cases. State the problem, what was tried,
and the options:
- A phase fails **3 rounds in a row**
- QA believes a test case is wrong, or an AC must be read differently
- Something outside the locked plan or spec is needed (files or systems out of
  scope, an architecture change, a new dependency)
- An environment error you cannot fix yourself (build, Unity license, test
  runner)

Never lower the test bar to get past a blocker.
