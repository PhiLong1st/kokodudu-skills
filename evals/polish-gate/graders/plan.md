---
type: llm
---
Pass only if the final message shows a plan that lists the violations found in `Player.cs` with line, rule and before/after, separates safe edits from items that need a decision (renaming the public type or the public field `Health` belongs in the decision group, not the safe group), says which style source it used, and ends by asking the user for approval before editing anything. Fail if the message says edits were already applied.
