---
name: test-coverage
description: Measure test coverage, identify gaps, and generate missing tests to reach 80%+.
---

Measure coverage and write tests for under-covered files.

## Step 1: Run Coverage

| Indicator | Command |
|-----------|---------|
| `pytest.ini` / `pyproject.toml` with pytest | `pytest --cov=src --cov-report=json --cov-report=term-missing` |
| Pure `unittest` | `python -m coverage run -m unittest discover && python -m coverage report` |
| C extension (`*.pyx`) | `pytest --cov=src --cov-report=json` (coverage on Python wrapper only) |

## Step 2: Analyze Coverage

1. List files **below 80%**, sorted worst-first.
2. For each, identify:
   - Untested functions or methods.
   - Missing branch coverage (if/else, early returns, error paths).
   - ML-specific gaps: evaluation paths, metric edge cases, data augmentation branches.

## Step 3: Generate Missing Tests

Priority order:
1. **Happy path**: correct inputs, expected outputs.
2. **Error handling**: invalid inputs, missing files, OOM conditions.
3. **Edge cases**: empty arrays, zero-length sequences, single-element batches, `NaN`/`inf` in tensors.
4. **Branch coverage**: each if/else, try/except.

Rules:
- Tests go in `tests/` mirroring `src/` structure.
- Use `pytest`. Follow existing fixture and parametrize patterns in the project.
- Mock external dependencies: file I/O, network calls. Guard CUDA with `@pytest.mark.skipif`.
- ML models: assert output **shape**, not exact values, unless testing a known formula.
- Mark slow and GPU tests `@pytest.mark.slow` and `@pytest.mark.gpu`.

## Step 4: Verify

1. Run the full suite. All tests must pass.
2. Re-run coverage.
3. If a file is still below 80%, say why (dead code path, GPU-only branch).

## Step 5: Report

```
Coverage Report
──────────────────────────────────────────
File                        Before   After
src/models/transformer.py    42%      83%
src/data/augmentation.py     31%      85%
──────────────────────────────────────────
Overall:                     68%      84%  PASS
```
