---
name: python-testing
description: pytest patterns, fixtures, parametrization, mocking, async testing, and ML-specific test strategies (shape checks, overfit sanity, GPU marks).
origin: affaan-m/everything-claude-code (adapted)
---

# Python Testing Patterns

## When to Activate
- Writing new Python code (TDD: red → green → refactor)
- Designing test suites or reviewing coverage
- Setting up pytest infrastructure

---

## TDD Cycle

1. **RED** — write a failing test
2. **GREEN** — write minimal code to pass
3. **REFACTOR** — improve while keeping green

Coverage target: **80%+** on `src/`. Critical paths: 100%.

```bash
pytest --cov=src --cov-report=term-missing --cov-fail-under=80
```

---

## pytest Basics

```python
# Arrange-Act-Assert
def test_cosine_similarity_orthogonal():
    a, b = np.array([1.0, 0.0]), np.array([0.0, 1.0])
    result = cosine_similarity(a, b)
    assert result == pytest.approx(0.0)
```

Descriptive test names explain the behavior:
```
test_returns_empty_when_no_samples_match
test_raises_value_error_on_negative_input
test_forward_pass_produces_correct_output_shape
```

---

## Fixtures

```python
# conftest.py
@pytest.fixture
def small_batch():
    return {
        "input_ids": torch.randint(0, 100, (4, 16)),  # (B=4, T=16)
        "labels":    torch.randint(0, 10,  (4,)),
    }

@pytest.fixture(scope="session")
def shared_tokenizer():
    return Tokenizer.from_pretrained("...")

@pytest.fixture
def tmp_checkpoint(tmp_path):
    p = tmp_path / "ckpt.pt"
    torch.save({"epoch": 0}, p)
    return p
```

Fixture scopes: `function` (default) → `module` → `session`. Use `session` for expensive resources like model loads.

---

## Parametrize

```python
@pytest.mark.parametrize("batch,seq", [(1, 1), (4, 128), (16, 512)])
def test_forward_shape(batch, seq):
    model = MyModel()
    out = model(torch.randint(0, 100, (batch, seq)))
    assert out.shape[0] == batch
    assert out.shape[1] == seq

@pytest.mark.parametrize("input,expected", [
    ("valid@email.com", True),
    ("missing-at",      False),
], ids=["valid", "missing-at"])
def test_email_validation(input, expected):
    assert is_valid_email(input) is expected
```

---

## Markers

```python
# Mark in pyproject.toml:
# markers = ["slow", "gpu"]

@pytest.mark.slow
def test_full_training_loop(): ...

@pytest.mark.gpu
@pytest.mark.skipif(not torch.cuda.is_available(), reason="no GPU")
def test_model_on_gpu():
    model = MyModel().cuda()
    out = model(torch.randint(0, 10, (2, 8)).cuda())
    assert out.device.type == "cuda"
```

Run without slow/GPU tests: `pytest -m "not slow and not gpu"`

---

## ML-Specific Patterns

**Test shape, not exact values:**

```python
def test_attention_output_shape(small_batch):
    model = Transformer(vocab=100, hidden=64)
    out = model(small_batch["input_ids"])
    assert out.shape == (4, 16, 100)  # (B, T, vocab)
```

**Overfit sanity check:**

```python
def test_loss_decreases_on_tiny_batch():
    model = MyModel(vocab=10, hidden=32)
    optim = torch.optim.Adam(model.parameters(), lr=1e-2)
    x = torch.randint(0, 10, (2, 8))
    losses = []
    for _ in range(20):
        loss = model.compute_loss(x)
        optim.zero_grad(); loss.backward(); optim.step()
        losses.append(loss.item())
    assert losses[-1] < losses[0], "loss did not decrease"
```

**Use synthetic data only — never real data in tests.**

---

## Mocking

```python
from unittest.mock import patch, Mock

@patch("mypackage.external_api_call")
def test_with_mock(api_mock):
    api_mock.return_value = {"status": "ok"}
    result = my_function()
    api_mock.assert_called_once()
    assert result["status"] == "ok"

# Mock exception
api_mock.side_effect = ConnectionError("network error")
```

---

## Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_async_fetch():
    result = await fetch_data("http://...")
    assert result is not None
```

---

## Test Structure

```
tests/
  conftest.py              # shared fixtures
  models/
    test_transformer.py    # mirrors src/models/transformer.py
  data/
    test_dataset.py
  utils/
    test_metrics.py
```

---

## pytest Configuration (pyproject.toml)

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
markers = [
    "slow: marks tests as slow (deselect with '-m not slow')",
    "gpu: requires CUDA GPU",
]
```

---

## Running Tests

```bash
pytest                          # all tests
pytest -m "not slow and not gpu"  # fast tests only
pytest -x                       # stop on first failure
pytest --lf                     # re-run last failures
pytest -k "test_forward"        # pattern match
pytest --pdb                    # drop into debugger on failure
```
