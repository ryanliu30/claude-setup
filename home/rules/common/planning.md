# Planning

Plan mode is the harness feature entered with `/plan` or the mode switch. It gates tools
read-only, writes the plan to a file, and requires approval. These rules add only what the
harness does not know about this stack.

## Offer a Grilling

On entering plan mode, before any research, file reading, or draft, ask the user through
AskUserQuestion whether they want to be grilled about the task first. This holds for both entry
points, `/plan` and the mode switch.

- Yes: run the `grilling` skill to completion. Stop when the frontier is empty and the user
  confirms shared understanding, then write the plan. The plan records what the grilling settled.
- No: research and write the plan directly.

Skip the question when the user has already said to grill or to skip it, or when the task has
nothing to decide. In the last case, say so in one line.

## What a plan must contain

- Ordered list of files to create or modify, each with a one-line rationale.
- Key design decisions with the chosen trade-off, for example "dataclasses over pydantic because
  no runtime validation is needed".
- Test strategy per phase, naming the level: unit, integration, or shape-only.
- Phases needing ML-specific care, named: data leakage, seeding, GPU memory budget, or breaking
  compatibility with an already-generated dataset.
- Performance considerations when relevant: batch size, memory budget, Cython versus pure Python.

One screen. Bullets, not paragraphs. Each phase independently testable.

Execution happens in a worktree and is not merged automatically. See
`rules/common/git-workflow.md`, "Plan Mode Work Happens in a Worktree".
