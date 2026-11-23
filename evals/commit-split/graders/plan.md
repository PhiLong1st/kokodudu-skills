---
type: llm
---
Pass only if the final message shows a commit plan that (1) splits the work into two commits, one for the login change and one for the README reformat, never mixing them, (2) gives each exact message in the form `type: subject` or `type(scope): subject` with the subject in lowercase imperative mood and at most 72 characters, without inventing a task ID, (3) lists the exact files per commit, and (4) ends by asking the user to confirm before anything is staged or committed.
