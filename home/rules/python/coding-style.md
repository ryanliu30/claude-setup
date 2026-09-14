---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Coding Style

> Extends [common/coding-style.md](../common/coding-style.md).

## Standards

- **PEP 8**: enforced by `ruff`.
- **Type annotations** on all public function signatures. Use `from __future__ import annotations` for forward references.
- **Python ≥3.10** syntax: `X | Y` unions, `match` where it fits.

## Immutability

Prefer immutable data for DTOs and result structs:

```python
from dataclasses import dataclass
from typing import NamedTuple

@dataclass(frozen=True)
class ModelSpec:
    hidden_dim: int
    num_layers: int
    dropout: float = 0.1

class Batch(NamedTuple):
    inputs: torch.Tensor   # (B, T)
    labels: torch.Tensor   # (B,)
```

**Exception, ML training configs**: Hydra + OmegaConf structured configs, `@dataclass` without `frozen=True`, since Hydra composes and overrides configs by mutation. See `rules/python/patterns.md`.

## Formatting Toolchain

Pre-commit hooks, run by git on commit:

| Hook | Command | Scope |
|------|---------|-------|
| `ruff-check` | `ruff check --fix` | `src/` Python files |
| `ruff-format` | `ruff format` | `src/` Python files |
| `cython-lint` | `cython-lint` | all `.pyx` files |

`ruff` formats and lints. Do not introduce `black`, `isort`, or `flake8`.

Run manually through pre-commit only:
```bash
pre-commit run --all-files
pre-commit run --files src/model.py tests/test_model.py
```

## ML / NumPy Conventions

- Document tensor shapes in the docstring when non-obvious:
  ```python
  def attention(q: Tensor, k: Tensor, v: Tensor) -> Tensor:
      """Scaled dot-product attention.

      Args:
          q: Query tensor of shape (B, H, T, D).
          k: Key tensor of shape (B, H, S, D).
          v: Value tensor of shape (B, H, S, D).
      Returns:
          Output tensor of shape (B, H, T, D).
      """
  ```
- `einops.rearrange`/`einops.reduce` for tensor manipulation.
- `@torch.no_grad()` on inference and evaluation methods.

## Docstrings

Google style. After every edit to a source file, check all three levels:

1. **Module**: the summary still describes the file, and the public API list, if present, matches the current symbols.
2. **Class**: the description, `Attributes:`, and examples match the current fields and responsibilities.
3. **Function**: `Args:`, `Returns:`, and `Raises:` match the current signature and behavior.

Add any docstring that is missing where required.

### When docstrings are required

| Level | Required when |
|-------|--------------|
| Module | always, for every `src/` file |
| Class | always, for every public class |
| Method/function | any public function; any non-trivial private function |
| Skip | trivial getters/setters, `__repr__`, private one-liners |

### Format

```python
"""One-line summary (imperative mood, ≤79 chars).

Extended description if the why or how is non-obvious.
"""
```

```python
class TransformerBlock:
    """Single transformer block with self-attention and FFN.

    Attributes:
        hidden_dim: Dimension of the model's hidden states.
        num_heads: Number of attention heads.
    """
```

```python
def load_checkpoint(path: str, device: str = "cpu") -> dict:
    """Load a model checkpoint from disk.

    Args:
        path: Path to the `.pt` checkpoint file.
        device: Target device string.

    Returns:
        State dict ready for `model.load_state_dict()`.

    Raises:
        FileNotFoundError: If path does not exist.
    """
```

Tensor shapes go inline in `Args:`/`Returns:`: `q: Query of shape (B, H, T, D).`
