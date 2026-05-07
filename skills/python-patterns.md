---
name: python-patterns
description: Pythonic idioms, type hints, error handling, context managers, generators, dataclasses, concurrency, and package organization for robust Python development.
origin: affaan-m/everything-claude-code (adapted)
---

# Python Development Patterns

## When to Activate
- Writing new Python code
- Reviewing or refactoring Python code
- Designing Python packages or modules

---

## Core Principles

**Readability counts.** Code should be obvious.

```python
# Good
def get_active_users(users: list[User]) -> list[User]:
    return [u for u in users if u.is_active]

# Bad
def get_active_users(u):
    return [x for x in u if x.a]
```

**EAFP over LBYL.** Prefer exception handling over pre-checks.

```python
# Good
try:
    return dictionary[key]
except KeyError:
    return default
```

---

## Type Hints

Use built-in types (Python 3.10+):

```python
def process(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

T = TypeVar('T')

def first(items: list[T]) -> T | None:
    return items[0] if items else None
```

Prefer `Protocol` for duck typing over ABCs:

```python
from typing import Protocol

class Dataset(Protocol):
    def __len__(self) -> int: ...
    def __getitem__(self, idx: int) -> dict: ...
```

**Never use `Any`.** If more than three types are possible, create a container dataclass or split the method.

---

## Error Handling

```python
# Good: specific, chained
def load_config(path: str) -> Config:
    try:
        with open(path) as f:
            return Config.from_json(f.read())
    except FileNotFoundError as e:
        raise ConfigError(f"config not found: {path}") from e
    except json.JSONDecodeError as e:
        raise ConfigError(f"invalid JSON: {path}") from e

# Bad: bare except
try:
    ...
except:
    pass  # always wrong
```

Custom exception hierarchy:

```python
class AppError(Exception): ...
class ValidationError(AppError): ...
class NotFoundError(AppError): ...
```

---

## Context Managers

```python
from contextlib import contextmanager

@contextmanager
def timer(label: str):
    t0 = time.perf_counter()
    yield
    print(f"{label}: {time.perf_counter() - t0:.3f}s")

with timer("forward pass"):
    out = model(x)
```

---

## Comprehensions and Generators

```python
# list comprehension for simple transforms
names = [u.name for u in users if u.is_active]

# generator for large sequences consumed once
total = sum(x ** 2 for x in range(1_000_000))

# generator function for streaming
def read_jsonl(path: str) -> Iterator[dict]:
    with open(path) as f:
        for line in f:
            yield json.loads(line)
```

Complex comprehensions — expand into a function instead.

---

## Dataclasses

For **data containers and DTOs**, use `frozen=True`:

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class ModelSpec:
    hidden_dim: int
    num_layers: int
    dropout: float = 0.1
```

For **ML training configuration**, use Hydra + OmegaConf structured configs. Do **not** use `frozen=True` — Hydra needs mutability for config composition and CLI overrides:

```python
from dataclasses import dataclass, field
from omegaconf import MISSING, DictConfig
from hydra.core.config_store import ConfigStore
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
    data_dir: str = MISSING  # must be provided; caught at startup

cs = ConfigStore.instance()
cs.store(name="config", node=Config)

@hydra.main(config_path="conf", config_name="config", version_base=None)
def train(cfg: DictConfig) -> None:
    # Override from CLI: python train.py train.lr=1e-3 train.batch_size=64
    run_training(cfg)
```

---

## Useful Stdlib Patterns

```python
from functools import lru_cache, cache
from itertools import islice

@cache  # unbounded, Python 3.9+
def tokenize(text: str) -> list[int]: ...

# batch an iterable
def batched(it, n):
    it = iter(it)
    while chunk := list(islice(it, n)):
        yield chunk
```

---

## Logging (not print)

```python
import logging
logger = logging.getLogger(__name__)

logger.info("epoch %d  loss=%.4f", epoch, loss)
logger.warning("OOM on batch %d — skipping", i)
```

---

## Concurrency

**Threads for I/O-bound:**

```python
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
    results = list(ex.map(fetch_url, urls))
```

**Processes for CPU-bound:**

```python
with concurrent.futures.ProcessPoolExecutor() as ex:
    results = list(ex.map(process_chunk, chunks))
```

---

## Anti-Patterns

```python
# Bad: mutable default argument
def append_to(item, items=[]):  ...
# Good
def append_to(item, items=None):
    if items is None:
        items = []
    ...

# Bad: type() check
if type(obj) == list: ...
# Good
if isinstance(obj, list): ...

# Bad: compare to None with ==
if value == None: ...
# Good
if value is None: ...

# Bad: from module import *
# Good: explicit imports
```

---

## Tooling

Format and lint with `ruff` only (no `black`, no `isort`):

```bash
ruff format src/
ruff check --fix src/
```
