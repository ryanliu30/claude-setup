---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.cc"
  - "**/*.hh"
  - "**/*.cxx"
  - "**/*.h"
  - "**/*.pyx"
  - "**/*.pxd"
  - "**/CMakeLists.txt"
  - "**/setup.py"
---

# C++ and Cython Coding Style

> Extends [common/coding-style.md](../common/coding-style.md).

## Modern C++ (C++17/20)

- `auto` only when the type is obvious from context.
- `constexpr` for compile-time constants; `const` for runtime constants.
- Structured bindings: `auto [key, val] = map_entry;`
- Range-based for loops unless the index is needed.
- `std::optional<T>` instead of sentinel values or out-parameters.
- `std::string_view` for non-owning string references.

## Resource Management (RAII)

No manual `new`/`delete`:

```cpp
// Good
auto buf = std::make_unique<float[]>(n);
auto model = std::make_shared<Model>(config);

// Bad
float* buf = new float[n];
```

## Ownership Semantics

- `std::unique_ptr`: exclusive ownership (default choice).
- `std::shared_ptr`: shared ownership, only when needed.
- Raw pointers and references: non-owning views only.

## Naming Conventions

| Entity | Convention | Example |
|--------|-----------|---------|
| Types/Classes | `PascalCase` | `AttentionLayer` |
| Functions/Methods | `snake_case` | `forward_pass()` |
| Private members | `snake_case_` | `hidden_dim_` |
| Constants | `kPascalCase` or `UPPER_SNAKE` | `kMaxSeqLen` |
| Namespaces | `lowercase` | `namespace ml` |

## Formatting

Use `clang-format` with a `.clang-format` file at the project root. Run before committing:
```bash
clang-format -i src/**/*.cpp include/**/*.hpp
```

## Error Handling

- Exceptions for exceptional conditions, not flow control.
- Prefer `std::expected<T, E>` (C++23) or `std::optional<T>` for expected failures.
- Never catch `...` without re-throwing.

## Cython Style

```python
# cython: language_level=3
# cython: boundscheck=False, wraparound=False  # only after correctness verified

import numpy as np
cimport numpy as np

def dot_product(
    double[::1] a,   # typed memoryview, no Python overhead
    double[::1] b,
) -> double:
    cdef int n = a.shape[0]
    cdef double result = 0.0
    cdef int i
    for i in range(n):
        result += a[i] * b[i]
    return result
```

Rules:
- Typed memoryviews (`double[::1]`, `float[:, ::1]`) for array arguments.
- `cdef` for C-only functions (not callable from Python).
- `cpdef` only when Python access is needed.
- Wrap C++ classes in `cdef class`; expose only what Python needs.
- Use `with nogil:` for long-running C/C++ calls that don't touch Python objects.
- Test both the Cython path and a pure-Python fallback when one exists.

## Build Integration

New Python extensions use `scikit-build-core` or `meson-python`, not `setup.py`. Standalone C++ libraries use CMake.

```toml
# pyproject.toml
[build-system]
requires = ["scikit-build-core", "cython"]
build-backend = "scikit_build_core.build"
```
