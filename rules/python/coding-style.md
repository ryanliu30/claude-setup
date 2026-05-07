---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Coding Style

> Extends [common/coding-style.md](../common/coding-style.md).

## Standards

- **PEP 8** — enforced by `ruff`.
- **Type annotations** on all public function signatures. Use `from __future__ import annotations` for forward references.
- **Python ≥3.10** syntax preferred: `X | Y` unions, `match` statements where appropriate.

## Immutability

Prefer immutable data:

```python
from dataclasses import dataclass
from typing import NamedTuple

@dataclass(frozen=True)
class ModelConfig:
    hidden_dim: int
    num_layers: int
    dropout: float = 0.1

class Batch(NamedTuple):
    inputs: torch.Tensor   # (B, T)
    labels: torch.Tensor   # (B,)
```

## Formatting Toolchain

Pre-commit hooks (run automatically on commit):

| Hook | Command | Scope |
|------|---------|-------|
| `ruff-check` | `ruff check --fix` | `src/` Python files |
| `ruff-format` | `ruff format` | `src/` Python files |
| `cython-lint` | `cython-lint` | all `.pyx` files |

`ruff` handles both formatting and linting — no `black`, no `isort`, no separate flake8. Do not introduce those tools or suggest them.

To run manually before committing:
```bash
ruff check --fix src/
ruff format src/
cython-lint **/*.pyx
```

## ML / NumPy Conventions

- Document tensor shapes in the first docstring line when non-obvious:
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
- Use `einops.rearrange`/`einops.reduce` for readable tensor manipulation.
- Use `@torch.no_grad()` decorator for inference/evaluation methods.

## Docstrings

Google style:

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

Skip docstrings for trivial getters and private helpers.
