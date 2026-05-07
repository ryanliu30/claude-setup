# Testing Requirements

## Coverage Target: 80%+

All three test levels are required:
1. **Unit** — individual functions, classes, utilities.
2. **Integration** — data pipelines, model components working together.
3. **End-to-end** — full training/inference loop on a small synthetic dataset.

## Test-Driven Development (preferred for non-experimental code)

1. Write test first (RED).
2. Run test — it must FAIL.
3. Write minimal implementation (GREEN).
4. Run test — it must PASS.
5. Refactor (IMPROVE).
6. Verify coverage ≥80%.

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
- Mark slow tests: `@pytest.mark.slow` — exclude from default run with `pytest -m "not slow"`.
- Always test with a **small synthetic dataset** (e.g., batch of 4, sequence length 8) — never use real data in tests.
- Test that training loss decreases over 5–10 steps on a small overfit case (sanity check).

## Troubleshooting

- Check test isolation first — shared mutable state causes flaky tests.
- Verify mock return values match real object interfaces.
- Fix the implementation if the test is correct; fix the test if the expected value was stale.
