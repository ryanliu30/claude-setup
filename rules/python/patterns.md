---
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Patterns

> Extends [common/coding-style.md](../common/coding-style.md).

## Protocols (Structural Subtyping)

Prefer `Protocol` over abstract base classes for duck typing:

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Dataset(Protocol):
    def __len__(self) -> int: ...
    def __getitem__(self, idx: int) -> dict: ...
```

## Dataclasses as Configuration

Use `dataclass` for configs; `frozen=True` for immutability:

```python
from dataclasses import dataclass, field

@dataclass
class TrainConfig:
    lr: float = 1e-4
    batch_size: int = 32
    epochs: int = 100
    optimizer: str = "adamw"
    extra_args: dict = field(default_factory=dict)
```

## Context Managers

Use `contextlib.contextmanager` for resource management:

```python
from contextlib import contextmanager

@contextmanager
def timer(label: str):
    import time
    t0 = time.perf_counter()
    yield
    print(f"{label}: {time.perf_counter() - t0:.3f}s")
```

## Generators for Large Data

```python
def read_jsonl(path: str):
    with open(path) as f:
        for line in f:
            yield json.loads(line)
```

## Functional Utilities

Prefer `itertools` and comprehensions over manual loops:

```python
from itertools import islice, chain

# Batch an iterable
def batched(iterable, n):
    it = iter(iterable)
    while batch := list(islice(it, n)):
        yield batch
```

## Caching

```python
from functools import lru_cache, cache

@cache  # Python 3.9+, unbounded
def tokenize(text: str) -> list[int]: ...

@lru_cache(maxsize=1024)
def lookup_embedding(token_id: int) -> list[float]: ...
```

## Logging (not print)

```python
import logging

logger = logging.getLogger(__name__)

logger.info("Epoch %d loss=%.4f", epoch, loss)
logger.warning("CUDA OOM on batch %d — reducing batch size", i)
```
