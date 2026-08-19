---
description: Deep Python-specific code review using static analysis tools.
---

Find modified `.py` files and perform a thorough Python code review.

## Step 1: Find Changed Files

```bash
git diff --name-only HEAD | grep '\.py$'
# or for staged:
git diff --cached --name-only | grep '\.py$'
```

If no Python files changed, say so and stop.

## Step 2: Run Static Analysis

Run the following tools (skip gracefully if not installed):

```bash
ruff check <files>
ruff format --check <files>
cython-lint <pyx_files>   # if any .pyx files changed
bandit -r <files> -ll     # security scan, low severity and above (if installed)
```

## Step 3: Review by Severity

**CRITICAL** (block commit):
- SQL injection via string concatenation
- `eval()`/`exec()` on untrusted input
- `pickle.load()` from untrusted source
- Hardcoded credentials or API keys
- Data leakage (test data accessed before split)

**HIGH** (should fix):
- Missing type hints on public functions
- Mutable default arguments (`def f(x=[])`)
- Bare `except: pass` or exception swallowing
- File/resource not closed properly (missing `with`)
- Undeterministic ML operations without seed

**MEDIUM** (consider fixing):
- PEP 8 / ruff violations not auto-fixed
- Missing docstrings on public functions/classes
- `print()` instead of `logging`
- Inefficient string concatenation in loops
- `for i in range(len(x))` instead of `for item in x`

**LOW** (optional):
- Cosmetic style, variable naming preferences.

## Step 4: Framework-Specific Checks

- **PyTorch**: missing `model.eval()` before inference, no `torch.no_grad()`, incorrect loss `.backward()` usage, GPU tensor sent to CPU without `.detach()`.
- **NumPy**: unnecessary Python loops over arrays, shape mismatches not caught at entry points.
- **scikit-learn**: fitting on test split, pipeline steps not wrapped for cross-validation.

## Outcome

- **PASS**: no CRITICAL or HIGH issues.
- **WARNING**: MEDIUM issues only.
- **FAIL**: CRITICAL or HIGH issues present, do not commit.
