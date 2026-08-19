# Testing Requirements

## Coverage Target: 80%+

All three test levels are required:
1. **Unit**: individual functions, classes, utilities.
2. **Integration**: data pipelines, model components working together.
3. **End-to-end**: full training/inference loop on a small synthetic dataset.

## Test-Driven Development

**Binding** for library code under `src/` and anything imported by it: new features, refactors,
and bug fixes start with a failing test. **Advisory** for scripts, notebooks, and exploratory
work, where one assert-based check is enough.

1. RED: write the test first, run it, and confirm it FAILS rather than errors.
2. GREEN: write the minimal implementation, run it, and confirm it PASSES.
3. REFACTOR: improve the code with the green suite as the safety net.
4. Gate: `pytest --cov=src --cov-fail-under=80` must pass before the task is done.

Procedure, with git checkpoints and ML-specific patterns: the `tdd-workflow` skill.

## Test Structure (AAA)

```python
def test_cosine_similarity_orthogonal_vectors():
    # Arrange
    a = np.array([1.0, 0.0])
    b = np.array([0.0, 1.0])
    # Act
    result = cosine_similarity(a, b)
    # Assert
    assert result == pytest.approx(0.0)
```

## Test Naming

Use descriptive names that explain the behavior:
```
test_returns_empty_when_no_samples_match
test_raises_value_error_on_negative_input
test_forward_pass_produces_correct_output_shape
```

## ML-Specific Rules

- Test output **shapes**, not exact float values (use `pytest.approx` with tolerance when values matter).
- Mark GPU tests: `@pytest.mark.gpu` and skip in CI without GPU: `@pytest.mark.skipif(not torch.cuda.is_available(), reason="no GPU")`.
- Mark slow tests: `@pytest.mark.slow`, exclude from default run with `pytest -m "not slow"`.
- Always test with a **small synthetic dataset** (e.g., batch of 4, sequence length 8); never use real data in tests.
- Test that training loss decreases over 5–10 steps on a small overfit case (sanity check).

## Troubleshooting

- Check test isolation first, shared mutable state causes flaky tests.
- Verify mock return values match real object interfaces.
- Fix the implementation if the test is correct; fix the test if the expected value was stale.
