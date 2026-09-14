---
name: cpp-review
description: C++ and Cython code review focused on memory safety, modern C++, and Python extension correctness.
context: fork
---

Review the modified C++/Cython files.

## Step 1: Find Changed Files

```bash
git diff --name-only HEAD | grep -E '\.(cpp|hpp|cc|hh|cxx|h|pyx|pxd)$'
```

## Step 2: Run Static Analysis

```bash
clang-format --dry-run -Werror <cpp_files>   # formatting
clang-tidy <cpp_files> -- -std=c++17         # linting
cppcheck --enable=all <cpp_files>            # static analysis
```

## Step 3: Review by Severity

**CRITICAL** (block commit):
- Raw `new`/`delete` without RAII wrapper
- Buffer overflow or out-of-bounds array access
- Use-after-free or double-free
- Data race: shared mutable state touched from multiple threads without synchronization
- Null pointer dereference without guard
- Command injection via `system()` or `popen()` with untrusted input

**HIGH** (should fix):
- Rule of Five violation: custom destructor without copy/move constructor and assignment
- Missing `std::lock_guard`/`std::unique_lock` around shared mutable state
- C-style casts instead of `static_cast`/`reinterpret_cast`
- `std::shared_ptr` where `std::unique_ptr` suffices
- Returning raw pointer to heap-allocated memory from a function

**Cython-specific HIGH**:
- Missing `with nogil:` around long-running C calls that release the GIL
- Python object manipulation inside `nogil` block
- Array arguments without typed memoryviews
- Missing `boundscheck=False` annotation with no safety justification

**MEDIUM** (consider fixing):
- Unnecessary copies; pass large objects by const reference
- Missing `[[nodiscard]]` on functions whose return value must be checked
- `auto` where the type is not obvious from context
- Missing `constexpr` on compile-time constants

## Step 4: Build Verification

```bash
cmake --build build/ 2>&1 | head -50
# or
make -j$(nproc) 2>&1 | head -50
```

The build must be clean: zero warnings with `-Wall -Wextra`.

## Outcome

- **PASS**: no CRITICAL or HIGH issues, clean build.
- **WARNING**: MEDIUM issues, or build warnings.
- **FAIL**: CRITICAL or HIGH issues, do not commit.
