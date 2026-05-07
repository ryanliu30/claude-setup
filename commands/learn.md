---
description: Extract reusable patterns from the current session and save them as skill files.
---

Analyze the current session and extract any patterns worth saving as permanent skills.

## What to extract

Look for:
1. **Error resolution patterns** — non-obvious root cause + fix that would recur.
2. **ML-specific patterns** — debugging training instability, fixing shape mismatches, Cython profiling tricks.
3. **Workarounds** — library quirks, version-specific bugs, API limitations.
4. **Codebase conventions discovered** — implicit patterns not in docs.

## What NOT to extract

- Trivial fixes (typos, syntax errors, missing imports).
- One-time issues (transient API outages, machine-specific paths).
- Anything already documented in the project's README or CLAUDE.md.

## Output format

Create a skill file at `~/.claude/skills/learned/<pattern-name>.md`:

```markdown
# [Descriptive Pattern Name]

**Extracted:** [Date]
**Context:** [When this applies — be specific, e.g. "PyTorch training loops with mixed precision"]

## Problem
[What goes wrong and why — be concrete, not abstract]

## Solution
[The pattern/technique/workaround]

## Example
[Minimal code example if applicable]

## When to use
[Trigger conditions — what signals that this skill applies]
```

## Process

1. Review the session for extractable patterns.
2. Draft the skill file content.
3. Ask the user to confirm before saving.
4. Save to `~/.claude/skills/learned/`.

One skill file per pattern. Keep each focused and specific.
