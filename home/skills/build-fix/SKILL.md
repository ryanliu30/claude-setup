---
name: build-fix
description: Incrementally fix build, type, and lint errors with minimal, safe changes.
---

Fix build errors one at a time with the smallest change that resolves each. No refactors.

## Step 1: Detect Build System

| Indicator | Command |
|-----------|---------|
| `pyproject.toml` with mypy | `mypy . 2>&1` |
| `.pre-commit-config.yaml` | `pre-commit run --all-files 2>&1` |
| `setup.py` / `setup.cfg` with Cython | `python setup.py build_ext --inplace 2>&1` |
| `CMakeLists.txt` | `cmake --build build/ 2>&1` |
| `Makefile` with `build` target | `make build 2>&1` |
| `Cargo.toml` | `cargo build 2>&1` |

## Step 2: Parse and Group Errors

1. Run the build command and capture stderr.
2. Group errors by file path.
3. Sort by dependency: imports and types before logic errors.
4. Count the errors to track progress.

## Step 3: Fix Loop

For each error:
1. **Read** 10 lines around the error.
2. **Diagnose** the root cause: missing import, wrong type, syntax error, linker symbol.
3. **Fix** with the smallest change that resolves it.
4. **Re-run** to confirm the error is gone and none were added.

## Step 4: Guardrails

Stop and ask the user if:
- A fix introduces **more errors than it resolves**.
- The **same error persists after 3 attempts**.
- The fix requires **architectural changes**.
- Errors stem from **missing dependencies** (`pip install`, `conda install`, `brew install`).

## Step 5: Summary

Report:
- Errors fixed (file, line, what changed).
- Errors remaining, with why each needs manual attention.
- New errors introduced. Must be zero.
