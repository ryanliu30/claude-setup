# Planning

Plan mode is the harness feature, entered with `/plan` or the mode switch. It gates tools
read-only, writes the plan to a file, and requires explicit approval. Do not reimplement it as a
prompt; these rules only add what the harness does not know about this stack.

## What a plan must contain

- Ordered list of files to create or modify, each with a one-line rationale.
- Key design decisions with the chosen trade-off stated, for example "dataclasses over pydantic
  because no runtime validation is needed".
- Test strategy per phase, naming the level: unit, integration, or shape-only.
- Any phase needing ML-specific care, called out by name: data leakage, reproducibility and
  seeding, GPU memory budget, or breaking compatibility with an already-generated dataset.
- Performance considerations when relevant: batch size, memory budget, Cython versus pure Python.

Keep the plan to one screen. Bullet points, not paragraphs. Each phase should be independently
testable.

Execution happens in a worktree and is not merged automatically. See
`rules/common/git-workflow.md`, "Plan Mode Work Happens in a Worktree".
