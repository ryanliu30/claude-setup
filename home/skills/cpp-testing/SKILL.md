---
name: cpp-testing
description: C++ testing with GoogleTest/GoogleMock, CMake/CTest, sanitizers, TDD loop, and dependency injection patterns for C++17/20 projects.
origin: affaan-m/everything-claude-code (adapted)
---

# C++ Testing Patterns

## When to Activate
- Creating or fixing C++ unit and integration tests
- Designing test coverage strategies for C++ components
- Configuring CMake/CTest execution
- Troubleshooting flaky tests or memory/concurrency issues
- Integrating sanitizers into CI

---

## TDD Loop

**RED → GREEN → REFACTOR**

1. Write a failing test
2. Run it, it must fail
3. Write minimal code to pass
4. Run it, it must pass
5. Refactor while keeping tests green

---

## Project Structure

```
tests/
  unit/             # fast, isolated, no I/O
  integration/      # multi-component or file I/O
  testdata/         # fixtures, sample files
CMakeLists.txt
```

---

## CMake Setup

```cmake
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        main
)
FetchContent_MakeAvailable(googletest)

enable_testing()

add_executable(unit_tests tests/unit/test_attention.cpp)
target_link_libraries(unit_tests GTest::gtest_main GTest::gmock)
gtest_discover_tests(unit_tests)   # preferred over manual registration
```

Build and run:

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)
ctest --test-dir build --output-on-failure
```

---

## GoogleTest Basics

```cpp
#include <gtest/gtest.h>

TEST(AttentionTest, OutputShape) {
    Attention attn(/*heads=*/8, /*dim=*/64);
    auto out = attn.forward(query, key, value);
    EXPECT_EQ(out.rows(), query.rows());
    EXPECT_EQ(out.cols(), 64);
}

TEST(AttentionTest, ThrowsOnDimMismatch) {
    Attention attn(8, 64);
    EXPECT_THROW(attn.forward(bad_query, key, value), std::invalid_argument);
}
```

---

## GoogleMock

```cpp
#include <gmock/gmock.h>

class MockCheckpointer : public ICheckpointer {
public:
    MOCK_METHOD(void, save, (const Model&, const std::string&), (override));
    MOCK_METHOD(Model, load, (const std::string&), (override));
};

TEST(TrainerTest, SavesCheckpointAfterEpoch) {
    MockCheckpointer ckpt;
    EXPECT_CALL(ckpt, save(testing::_, testing::EndsWith(".pt")))
        .Times(1);

    Trainer trainer(&ckpt);
    trainer.run_epoch(data);
}
```

**Mocks vs. Fakes:**
- Mock, verify interactions (call count, args)
- Fake, stateful behavior with realistic responses (e.g., in-memory store)

Prefer **dependency injection** (pass as constructor arg) over global state to enable isolation:

```cpp
// Good: injectable
class Trainer {
public:
    explicit Trainer(ICheckpointer* ckpt) : ckpt_(ckpt) {}
private:
    ICheckpointer* ckpt_;
};

// Bad: static/global
class Trainer {
    void save() { GlobalCheckpointer::instance().save(...); }
};
```

---

## Fixtures

```cpp
class ModelTest : public ::testing::Test {
protected:
    void SetUp() override {
        model_ = std::make_unique<Transformer>(config_);
    }

    TransformerConfig config_{.hidden=64, .layers=2};
    std::unique_ptr<Transformer> model_;
};

TEST_F(ModelTest, ForwardDoesNotThrow) {
    EXPECT_NO_THROW(model_->forward(dummy_input_));
}
```

---

## Parametrized Tests

```cpp
class DotProductTest : public ::testing::TestWithParam<std::pair<int, int>> {};

TEST_P(DotProductTest, CorrectForVariousSizes) {
    auto [n, stride] = GetParam();
    auto a = random_vector(n), b = random_vector(n);
    EXPECT_NEAR(dot(a, b), reference_dot(a, b), 1e-5f);
}

INSTANTIATE_TEST_SUITE_P(
    Sizes, DotProductTest,
    ::testing::Values(
        std::make_pair(1, 1),
        std::make_pair(64, 1),
        std::make_pair(1024, 4)
    )
);
```

---

## Sanitizers

Enable in CMake for debug/CI builds:

```cmake
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(unit_tests PRIVATE
        -fsanitize=address,undefined
        -fno-omit-frame-pointer
    )
    target_link_options(unit_tests PRIVATE
        -fsanitize=address,undefined
    )
endif()
```

| Sanitizer | Catches |
|-----------|---------|
| AddressSanitizer (`-fsanitize=address`) | Buffer overflows, use-after-free |
| UBSanitizer (`-fsanitize=undefined`) | Undefined behavior, integer overflow |
| ThreadSanitizer (`-fsanitize=thread`) | Data races |

---

## Coverage

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="--coverage"
cmake --build build -j$(nproc)
ctest --test-dir build
lcov --capture --directory build --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
```

---

## Critical Guardrails

- **Never** use `sleep()` for synchronization, use condition variables or `std::latch`.
- Generate unique temp directories per test (`std::filesystem::temp_directory_path() / unique_name()`); clean up in `TearDown`.
- **Never** depend on wall-clock time or external network in unit tests.
- Run sanitizers in every CI pipeline.
