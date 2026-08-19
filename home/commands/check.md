---
model: haiku
---

Run the project's quality checks, auto-fix everything safe to fix, and report what remains.

## Steps

1. Detect the check system by looking for (in order):
   - `Makefile` with a `check` target → run `make check`
   - `.pre-commit-config.yaml` → run `pre-commit run --all-files`
   - `pyproject.toml` with mypy/pytest config → run `pre-commit run --all-files && mypy . && pytest`
   - Bare Python project → run `pre-commit run --all-files && python -m pytest`

   **Never** invoke `ruff`, `black`, `isort`, `flake8`, or other formatters/linters as direct shell
   commands. All formatting and linting must go through `pre-commit run`.

2. Capture the full output. For each failure category, apply fixes where safe:
   - **Formatting / Linting** (`pre-commit run --all-files`): always run; pre-commit will auto-fix
     what it can. Re-run once after fixes so the hooks pass cleanly.
   - **Linting**: fix rule violations that don't require logic changes (unused imports, style). Skip anything that would alter behavior.
   - **Type errors**: fix annotation issues properly.
     - In `src/`: **never** use `# type: ignore`, fix types correctly or flag as needing manual attention.
     - In test files: `# type: ignore` is acceptable only when it meaningfully reduces boilerplate.
     - Do **not** change runtime logic to satisfy the type checker.
   - **Test failures**: investigate root cause. Fix the test only if the test itself is wrong (stale expected value, wrong import). Do **not** change production logic to make tests pass, report those failures.

3. For C/C++ files, if `clang-format` is configured: run `clang-format -i <changed files>`.

4. Re-run the check suite to confirm all auto-fixable issues are resolved.

5. Re-stage any files that were modified by auto-fixes so they are included in the next commit:
   ```bash
   git diff --name-only | xargs git add
   ```

6. Produce a final summary with two sections:
   - **Fixed**: bullet list of what was resolved and how.
   - **Requires manual attention**: bullet list of remaining issues with a one-line explanation of why each needs a logic change.
