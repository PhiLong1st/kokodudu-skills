---
type: regex
pattern: '^\s*Co-Authored-By:'
flags: im
match: not_contains
---
The proposed messages must not carry a co-author trailer. A sentence that only says there is none does not count.
