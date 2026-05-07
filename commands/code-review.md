---
description: Review staged/changed code or a GitHub PR across security, quality, and correctness dimensions.
---

Perform a comprehensive code review. Detect the mode automatically:
- **Local mode**: `git diff HEAD` or `git diff --cached` shows changes.
- **PR mode**: a GitHub PR URL or number is provided.

## Review Checklist

For every changed file, check:

1. **Correctness**: logic errors, off-by-one, unhandled edge cases, silent failures.
2. **Type safety**: missing annotations, Any leakage, incorrect return types.
3. **Security**: hardcoded secrets, `eval`/`exec` on untrusted input, `pickle` from untrusted sources, SQL injection.
4. **Performance**: Python loops over large arrays (use NumPy/PyTorch), unnecessary copies, missing `torch.no_grad()` in inference.
5. **ML-specific**: data leakage (test set touched during training), undeterministic ops without seed, loss not reduced correctly, metric computed on wrong split.
6. **Completeness**: tests added for new code, docstrings on public API, no debug artifacts (`print`, `breakpoint`, commented-out code).
7. **Maintainability**: functions >50 lines, nesting >4 levels, magic numbers without explanation.

## Severity Levels

- **CRITICAL** (block): security vulnerability, data leakage, silent data corruption.
- **HIGH** (should fix): missing tests for non-trivial logic, type errors, performance regression.
- **MEDIUM** (consider fixing): style, docs, minor inefficiency.
- **LOW** (optional): cosmetic, preference.

## Outcome

- **APPROVE**: no CRITICAL or HIGH issues.
- **REQUEST CHANGES**: HIGH issues present.
- **BLOCK**: CRITICAL issues present.

For PRs, post findings with `gh pr review` if the `gh` CLI is available.
