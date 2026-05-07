---
description: Incrementally fix build, type, and lint errors with minimal, safe changes.
---

Fix build errors one at a time. Never make large refactors — smallest change that resolves each error.

## Step 1: Detect Build System

| Indicator | Command |
|-----------|---------|
| `pyproject.toml` with mypy | `mypy . 2>&1` |
| `pyproject.toml` with ruff | `ruff check . 2>&1` |
| `setup.py` / `setup.cfg` with Cython | `python setup.py build_ext --inplace 2>&1` |
| `CMakeLists.txt` | `cmake --build build/ 2>&1` |
| `Makefile` with `build` target | `make build 2>&1` |
| `Cargo.toml` | `cargo build 2>&1` |

## Step 2: Parse and Group Errors

1. Run the build command and capture stderr.
2. Group errors by file path.
3. Sort by dependency order — fix imports/types before logic errors.
4. Count total errors for progress tracking.

## Step 3: Fix Loop

For each error:
1. **Read** — use Read tool, 10 lines around the error line.
2. **Diagnose** — identify root cause (missing import, wrong type, syntax error, linker symbol).
3. **Fix minimally** — Edit tool, smallest change that resolves the error.
4. **Re-run** — verify the error is gone and no new errors introduced.
5. **Next** — move on.

## Step 4: Guardrails

Stop and ask the user if:
- A fix introduces **more errors than it resolves**.
- The **same error persists after 3 attempts**.
- The fix requires **architectural changes** (not just a build fix).
- Errors stem from **missing dependencies** (`pip install`, `conda install`, `brew install`).

## Step 5: Summary

Report:
- Errors fixed (file, line, what changed).
- Errors remaining (if any) with reason why they need manual attention.
- New errors introduced (should be zero).
