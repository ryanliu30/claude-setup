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

## ML Configuration, Hydra + OmegaConf

Use **Hydra** for ML config management. Define structured configs as plain `@dataclass` (no `frozen=True`, Hydra requires mutability for config composition and override):

```python
from dataclasses import dataclass, field
from hydra.core.config_store import ConfigStore
from omegaconf import DictConfig, MISSING
import hydra

@dataclass
class TrainConfig:
    lr: float = 1e-4
    batch_size: int = 32
    epochs: int = 100
    optimizer: str = "adamw"

@dataclass
class Config:
    train: TrainConfig = field(default_factory=TrainConfig)
    data_dir: str = MISSING   # must be provided at runtime

cs = ConfigStore.instance()
cs.store(name="config", node=Config)

@hydra.main(config_path="conf", config_name="config", version_base=None)
def main(cfg: DictConfig) -> None:
    print(cfg.train.lr)   # override via CLI: train.lr=1e-3
```

Access runtime config as `DictConfig`; convert to a typed object with `OmegaConf.structured()` when needed. Never use bare `argparse` dicts or `pydantic` models for ML config.

Use plain `@dataclass` (without Hydra) only for non-config data containers (DTOs, result structs). For those, `frozen=True` is appropriate.

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
logger.warning("CUDA OOM on batch %d, reducing batch size", i)
```
