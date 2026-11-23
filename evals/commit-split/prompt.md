---
name: commit-split
tags: [commit, git]
runs: 3
max_turns: 25
timeout_seconds: 300
allowed_tools: [Bash, Read, Skill]
---

Prepare the fixture, then use the `kokodudu:commit` skill on it.

Fixture (work only inside a new directory made with `mktemp -d`, never touch any other directory):
1. `git init`, set a local `user.name` and `user.email`, create `src/login.txt` with the line `login v1` and `README.md` with the line `Docs v1`, then make the first commit with `git add src/login.txt README.md` followed by `git commit -m "fixture init"` (stage by explicit path, never `git add .` or `-A`).
2. Then change two unrelated things without committing: append the line `guard against empty session` to `src/login.txt`, and rewrite `README.md` as three reformatted lines of unrelated documentation text.
3. There is no task ID for this work.

Run the commit skill on the result. The user is not here to answer: do not wait for an answer, just do what the skill says up to the point where it needs approval.
