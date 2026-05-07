---
description: Structure an implementation plan and get explicit confirmation before writing any code.
---

Break down the request into a concrete implementation plan. **Do not write any code until the user explicitly confirms.**

## Steps

1. **Restate** the requirement in your own words to confirm understanding.
2. **Identify** dependencies, affected files, and potential risks.
3. **Break down** the work into ordered phases:
   - Each phase should be independently testable.
   - Call out any phase that requires ML-specific care (data leakage, reproducibility, GPU memory).
4. **Flag ambiguities**: ask at most two clarifying questions if the requirements are genuinely unclear.
5. **Present the plan** clearly and wait for the user to say "proceed", "yes", or similar.

## What to include in the plan

- Ordered list of files to create or modify, with brief rationale.
- Key design decisions and the chosen trade-off (e.g., "using dataclasses over pydantic because no runtime validation needed").
- Test strategy: what will be tested and at what level (unit, integration, shape-only).
- Any performance considerations (batch size, memory budget, Cython vs. pure Python).

## Constraints

- **No code before confirmation** — not even scaffolding.
- Keep the plan under one screen of text. Use bullet points, not paragraphs.
- If the task is trivial (< 20 lines, no design decisions), skip the plan and say so.
