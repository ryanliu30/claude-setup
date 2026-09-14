---
name: commit
model: sonnet
description: Analyze the currently staged git files and create a high-quality commit for them.
disable-model-invocation: true
---

Commit the currently staged files.

## Steps

1. Run `git diff --cached --stat`. If nothing is staged, tell the user and stop.
2. If `.pre-commit-config.yaml` exists and `.git/hooks/pre-commit` does not, run
   `pre-commit install`.
3. Run `git log --oneline -20` to infer the repo's commit style: casing, prefix format
   (`feat:`, `feat(scope):`, none), verb tense, subject length.
4. Run `git diff --cached` to read the full diff.
5. Work out *what* changed and *why* from the code, not the filenames.
6. Bug check: scan for syntax errors, broken imports, unhandled exceptions, and debug artifacts
   (`print`, `breakpoint()`, hardcoded paths). Flag anything found.
7. Run the full test suite. Use the command the repo documents in its README or Makefile
   (`pytest`, `uv run pytest`, `make test`); if none is documented, run `pytest -m "not slow"`.
   If the repo has no test suite, say so.
8. Write a commit message that:
   - Follows the repo's convention (Conventional Commits by default).
   - Has a subject of 72 chars or less, lowercase, imperative mood, stating *what* the commit does.
   - Has a body when the *why* or *how* is non-obvious: wrap at 72 chars, blank line after the
     subject.
   - Is specific. No "update", "fix things", "improve", "misc".
9. Run `git commit` with a heredoc. If the pre-commit hook rejects the commit or rewrites files,
   fix the cause, re-stage, and commit again.
10. Confirm with `git status`.

## Absolute rules
- **Never** add `Co-Authored-By` or any mention of Claude.
- **Never** pass `--no-verify`. If the hook blocks the commit, fix the code, not the gate.
- **Do not commit if bugs are found or the test suite fails.** Report the failures and stop.
- Do **not** stage additional files. Commit only what is already staged.
