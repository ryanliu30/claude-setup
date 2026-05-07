---
model: haiku
---

Run the project's quality checks, auto-fix everything safe to fix, and report what remains.

## Steps

1. Detect the check system by looking for (in order):
   - `Makefile` with a `check` target → run `make check`
   - `pyproject.toml` with ruff/mypy/pytest config → run `ruff check . && mypy . && pytest`
   - `setup.cfg` or `.flake8` → run `flake8 && pytest`
   - Bare Python project → run `ruff check . && python -m pytest`

2. Capture the full output. For each failure category, apply fixes where safe:
   - **Formatting** (`ruff format`, `black`, `isort`): always auto-fix.
   - **Linting**: fix rule violations that don't require logic changes (unused imports, style). Skip anything that would alter behavior.
   - **Type errors**: fix annotation issues properly.
     - In `src/`: **never** use `# type: ignore` — fix types correctly or flag as needing manual attention.
     - In test files: `# type: ignore` is acceptable only when it meaningfully reduces boilerplate.
     - Do **not** change runtime logic to satisfy the type checker.
   - **Test failures**: investigate root cause. Fix the test only if the test itself is wrong (stale expected value, wrong import). Do **not** change production logic to make tests pass — report those failures.

3. For C/C++ files, if `clang-format` is configured: run `clang-format -i <changed files>`.

4. Re-run the check suite to confirm all auto-fixable issues are resolved.

5. Produce a final summary with two sections:
   - **Fixed**: bullet list of what was resolved and how.
   - **Requires manual attention**: bullet list of remaining issues with a one-line explanation of why each needs a logic change.
