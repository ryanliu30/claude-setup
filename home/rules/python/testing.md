---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Testing

> Extends [common/testing.md](../common/testing.md).

## Framework

Use **pytest**. Configure in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
markers = [
    "slow: marks tests as slow (deselect with '-m not slow')",
    "gpu: requires CUDA GPU",
]
```

## Coverage

```bash
pytest --cov=src --cov-report=term-missing --cov-fail-under=80
```

## Test Organization

```
tests/
  models/
    test_transformer.py    # mirrors src/models/transformer.py
  data/
    test_dataset.py
  utils/
    test_metrics.py
  conftest.py              # shared fixtures
```

## Fixtures

```python
# conftest.py
import pytest
import torch

@pytest.fixture
def small_batch():
    return {
        "input_ids": torch.randint(0, 100, (4, 16)),  # (B=4, T=16)
        "labels": torch.randint(0, 10, (4,)),
    }

@pytest.fixture
def device():
    return "cuda" if torch.cuda.is_available() else "cpu"
```

## ML Test Patterns

```python
def test_forward_output_shape(small_batch, device):
    model = MyModel(vocab_size=100, hidden=64).to(device)
    out = model(small_batch["input_ids"].to(device))
    assert out.shape == (4, 16, 100)  # (B, T, vocab_size)

def test_loss_decreases_on_overfit():
    # sanity check: model can overfit a tiny batch
    model = MyModel(vocab_size=10, hidden=32)
    optim = torch.optim.Adam(model.parameters(), lr=1e-2)
    batch = torch.randint(0, 10, (2, 8))
    losses = []
    for _ in range(20):
        loss = model.compute_loss(batch)
        optim.zero_grad(); loss.backward(); optim.step()
        losses.append(loss.item())
    assert losses[-1] < losses[0], "Loss did not decrease"

@pytest.mark.gpu
@pytest.mark.skipif(not torch.cuda.is_available(), reason="no GPU")
def test_model_runs_on_gpu():
    model = MyModel().cuda()
    x = torch.randint(0, 10, (2, 8)).cuda()
    out = model(x)
    assert out.device.type == "cuda"
```

## Parametrize

```python
@pytest.mark.parametrize("batch_size,seq_len", [(1, 1), (4, 128), (16, 512)])
def test_forward_various_shapes(batch_size, seq_len):
    model = MyModel()
    x = torch.randint(0, 100, (batch_size, seq_len))
    out = model(x)
    assert out.shape[0] == batch_size
    assert out.shape[1] == seq_len
```
