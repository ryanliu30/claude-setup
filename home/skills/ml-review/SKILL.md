---
name: ml-review
description: ML-focused review of staged changes or a PR: data leakage, seeding, tensor and metric correctness, on top of the usual security and maintainability checks.
context: fork
---

ML-aware code review. Use it instead of the built-in `/code-review` when the diff touches models,
data pipelines, or training code. Detect the mode:
- **Local mode**: `git diff HEAD` or `git diff --cached` shows changes.
- **PR mode**: a GitHub PR URL or number is given.

## Review Checklist

For every changed file:

1. **Correctness**: logic errors, off-by-one, unhandled edge cases, silent failures.
2. **Type safety**: missing annotations, `Any` leakage, wrong return types.
3. **Security**: hardcoded secrets, `eval`/`exec` on untrusted input, `pickle` from untrusted sources, SQL injection.
4. **Performance**: Python loops over large arrays, unnecessary copies, missing `torch.no_grad()` in inference.
5. **ML-specific**: data leakage (test set touched during training), nondeterministic ops without seed, loss reduced wrong, metric computed on the wrong split.
6. **Completeness**: tests for new code, docstrings on public API, no debug artifacts (`print`, `breakpoint`, commented-out code).
7. **Maintainability**: functions over 50 lines, nesting over 4 levels, magic numbers.

## Severity Levels

- **CRITICAL** (block): security vulnerability, data leakage, silent data corruption.
- **HIGH** (should fix): missing tests for non-trivial logic, type errors, performance regression.
- **MEDIUM** (consider): style, docs, minor inefficiency.
- **LOW** (optional): cosmetic, preference.

## Outcome

- **APPROVE**: no CRITICAL or HIGH issues.
- **REQUEST CHANGES**: HIGH issues present.
- **BLOCK**: CRITICAL issues present.

For PRs, post findings with `gh pr review` if `gh` is available.
