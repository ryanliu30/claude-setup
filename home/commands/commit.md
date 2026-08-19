---
model: sonnet
---

Analyze the currently staged git files and create a high-quality commit for them.

## Steps

1. Run `git diff --cached --stat`. If nothing is staged, tell the user and stop.
2. If `.pre-commit-config.yaml` exists and `.git/hooks/pre-commit` does not, run
   `pre-commit install`. Git owns commit enforcement, so the hook must be registered before
   the first commit in a fresh clone.
3. Run `git log --oneline -20` to infer the repo's commit style: casing, prefix format
   (`feat:`, `feat(scope):`, none, etc.), verb tense, and typical subject length.
4. Run `git diff --cached` to read the full diff.
5. Analyze the diff deeply: understand *what* changed and *why*, inferring intent from the code,
   not just filenames.
6. Perform a bug check: scan for obvious issues such as syntax errors, broken imports,
   unhandled exceptions, and debug artifacts (e.g., `print` statements, `breakpoint()`,
   hardcoded paths). Flag any concerns.
7. Run the full test suite and read the result. Use the command the repo documents in its
   README or Makefile (`pytest`, `uv run pytest`, `make test`); if none is documented, run
   `pytest -m "not slow"`. If the repo has no test suite, say so explicitly rather than
   treating the step as passed.
8. Write a commit message that:
   - Follows the style convention already used in this repo (Conventional Commits by default).
   - Has a concise subject (72 chars or less), lowercase, imperative mood, stating *what* the
     commit does.
   - Includes a body when the *why* or *how* is non-obvious: wrap at 72 chars, separated from
     the subject by a blank line.
   - Is specific and precise. Avoid vague words like "update", "fix things", "improve", "misc".
9. Run `git commit` using a heredoc to preserve formatting. Git's `pre-commit` hook runs here;
   if it rejects the commit or rewrites files, fix the cause, re-stage, and commit again.
10. Confirm with `git status`.

## Absolute rules
- **Never** add `Co-Authored-By` or any mention of Claude.
- **Never** pass `--no-verify`. If the git hook blocks the commit, fix the code, not the gate.
- **Do not commit if bugs are detected or the test suite fails.** Report the failures to the
  user and refuse to commit until they are resolved.
- Do **not** stage additional files. Commit only what is already staged.
