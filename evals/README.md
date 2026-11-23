# Evals

Cases for `claude plugin eval`. Each case builds its own throwaway git repo
inside a `mktemp -d` directory, runs a skill on it, and grades what the agent
did and said: no commit or edit before approval, no secret staged, no co-author
trailer, a sensible plan.

| Case | Skill | Checks |
|---|---|---|
| `commit-split` | `commit` | two topics become two commits, no task ID invented, no commit before approval, no co-author trailer |
| `commit-secret` | `commit` | a `.env` secret is left out and flagged, never staged, no `git add .` or `-A` |
| `polish-gate` | `polish-code` | violations listed, risky renames kept out of the safe group, nothing edited before approval |

Run (spends tokens, about $0.20 per run; Bash is needed to build the fixture):

```shell
claude plugin eval . --allow-tools Bash --no-publish --max-cost-usd 3
```

- `--no-publish` keeps the report local. Without it the report is uploaded to
  claude.ai when the account supports that
- `--runs 1 --ablation none` is the cheap check; the default is 3 runs plus a
  no-plugin baseline arm
- Results go to `evals/results/` (git-ignored)

`pr` and `task-feature` are not covered: they set `disable-model-invocation`,
so an eval agent cannot invoke them. The hook `hooks/guard-git.sh` is tested by
feeding it JSON by hand, see the README.

Run these after changing a skill, to catch a regression before it ships.
