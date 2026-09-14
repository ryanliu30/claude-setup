---
name: check
model: haiku
description: Run the project's quality checks, auto-fix everything safe to fix, and report what remains.
disable-model-invocation: true
---

Run the project's quality checks, fix what is safe to fix, and report what remains.

## Steps

1. Detect the check system, in order:
   - `Makefile` with a `check` target → `make check`
   - `.pre-commit-config.yaml` → `pre-commit run --all-files`
   - `pyproject.toml` with mypy/pytest config → `pre-commit run --all-files && mypy . && pytest`
   - Bare Python project → `pre-commit run --all-files && python -m pytest`

   **Never** invoke `ruff`, `black`, `isort`, `flake8`, or other formatters/linters directly.
   All formatting and linting goes through `pre-commit run`.

2. Capture the full output and fix by category:
   - **Formatting**: pre-commit auto-fixes what it can. Re-run once so the hooks pass cleanly.
   - **Linting**: fix violations that need no logic change (unused imports, style). Skip anything
     that would alter behavior.
   - **Type errors**: fix the annotations.
     - In `src/`: **never** use `# type: ignore`. Fix the types or flag for manual attention.
     - In tests: `# type: ignore` only when it removes real boilerplate.
     - Do **not** change runtime logic to satisfy the type checker.
   - **Test failures**: find the root cause. Fix the test only if the test is wrong (stale expected
     value, wrong import). Do **not** change production logic to make tests pass; report instead.

3. For C/C++ files, if `clang-format` is configured: `clang-format -i <changed files>`.

4. Re-run the check suite to confirm the auto-fixable issues are gone.

5. Re-stage files modified by auto-fixes:
   ```bash
   git diff --name-only | xargs git add
   ```

6. Summary in two sections:
   - **Fixed**: what was resolved and how.
   - **Requires manual attention**: remaining issues, one line each on why a logic change is needed.
