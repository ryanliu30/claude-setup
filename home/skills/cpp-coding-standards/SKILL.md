---
name: cpp-coding-standards
description: Modern C++ best practices (C++17/20) from the C++ Core Guidelines, RAII, type safety, smart pointers, naming, error handling, concurrency, and templates.
origin: affaan-m/everything-claude-code (adapted)
---

# C++ Coding Standards (C++ Core Guidelines)

## When to Activate
- Writing or reviewing C++ or Cython C++ extension code
- Designing resource-management or concurrency patterns
- Code review of `.cpp` / `.hpp` files

---

## Six Core Principles

1. **RAII**: bind resource lifetime to object lifetime
2. **Immutability first**: `const`/`constexpr` by default; mutation is exceptional
3. **Type safety**: use the type system to catch errors at compile time
4. **Clear intent**: names and types communicate purpose
5. **Simplicity**: simple code is more likely to be correct
6. **Values over pointers**: prefer returning values and scoped objects

---

## Resource Management

No raw `new`/`delete`:

```cpp
// Good
auto buf   = std::make_unique<float[]>(n);
auto model = std::make_shared<Model>(config);

// Bad, never do this
float* buf = new float[n];
```

Ownership semantics:
- `std::unique_ptr`: exclusive ownership (default)
- `std::shared_ptr`: shared (only when truly needed; has overhead)
- Raw pointer / reference, non-owning view only

---

## Modern C++ (C++17/20)

```cpp
// structured bindings
auto [key, val] = map_entry;

// if constexpr
if constexpr (std::is_floating_point_v<T>) { ... }

// std::optional instead of sentinel values
std::optional<User> find_user(int id);

// std::string_view for non-owning string refs
void log(std::string_view msg);

// ranges (C++20)
auto evens = data | std::views::filter([](int x){ return x % 2 == 0; });
```

Always initialize variables. Prefer brace initialization `{}`. Use `nullptr` not `0`/`NULL`.

---

## Functions

- Pass inexpensive types (`int`, `float`, small structs) by value.
- Pass expensive types by `const&`.
- Return structs for multiple outputs, not output parameters.
- Single-argument constructors: mark `explicit`.
- Mark member functions `const` where applicable.

---

## Classes

Apply **Rule of Zero** (let compiler generate special members) or **Rule of Five** (define all five if managing resources):

```cpp
class Buffer {
public:
    explicit Buffer(std::size_t n) : data_(std::make_unique<float[]>(n)), n_(n) {}
    // Rule of Zero: unique_ptr handles copy/move/destroy correctly
private:
    std::unique_ptr<float[]> data_;
    std::size_t n_;
};
```

Use `enum class` over plain `enum`. Mark virtual overrides with `override`.

---

## Naming

| Entity | Convention | Example |
|--------|-----------|---------|
| Types/Classes | `PascalCase` | `AttentionLayer` |
| Functions/Methods | `snake_case` | `forward_pass()` |
| Private members | `snake_case_` | `hidden_dim_` |
| Constants | `kPascalCase` | `kMaxSeqLen` |
| Namespaces | `lowercase` | `namespace ml` |

---

## Error Handling

- Throw by value, catch by `const&`.
- Custom exception types over raw `std::runtime_error`.
- Never catch `...` without re-throwing.
- Prefer `std::expected<T, E>` (C++23) or `std::optional<T>` for expected failures.

---

## Concurrency

```cpp
// Good: RAII lock
{
    std::lock_guard<std::mutex> lock(mtx_);
    shared_data_.push_back(item);
}

// Bad: manual lock/unlock
mtx_.lock();
shared_data_.push_back(item);
mtx_.unlock();  // won't run if exception thrown
```

Avoid lock-free programming unless profiling proves it necessary.

---

## Templates (C++20)

Constrain with concepts:

```cpp
template <std::floating_point T>
T dot(std::span<const T> a, std::span<const T> b) { ... }

// Prefer 'using' over 'typedef'
using Matrix = std::vector<std::vector<float>>;
```

---

## Standard Library Preferences

| Prefer | Over |
|--------|------|
| `std::vector` | C arrays |
| `std::string` / `std::string_view` | `char*` |
| `std::array` | fixed-size C arrays |
| `std::span` (C++20) | pointer + length pairs |

---

## Pre-Commit Checklist

- [ ] All resources managed via RAII (no raw `new`/`delete`)
- [ ] Variables `const` unless mutation is required
- [ ] No C-style casts (`static_cast`/`reinterpret_cast` only)
- [ ] Single-argument constructors marked `explicit`
- [ ] Rule of Zero or Rule of Five applied
- [ ] Template parameters constrained with concepts (C++20)
- [ ] `clang-format` run on all changed files
