# Global Agent Guidelines

These guidelines apply to **all workspaces** and interactions. They are opinionated, ML/research-oriented, and designed for professional Python development with occasional C/C++/Cython work.

---

## I. Environment & Execution

**CRITICAL**: Before running any Python scripts, tests, or installing packages, ensure the correct environment is active.

### 1. Environment Priority
1. **Conda Environment**: Check if in the project README.md contains conda environment installation instructions. If so, use the conda environment. Otherwise, infer the potential environment name from the project name.
   - Use `which python` to check if an environment is active. If so, proceed to execution.
   - Run `conda activate <name>`. If unsure, run `conda env list`.
2. **Never use the base environment** for project work — always prefer isolation.

### 2. Pre-commit
- Always run `pre-commit` if it exists before committing.
- If no hook exists, run the project's test suite manually.
- Never invoke `ruff`, `cython-lint`, `black`, `isort`, or other formatters/linters directly as shell commands. Run them exclusively through `pre-commit run`.

---

## II. Coding Standards

**Check the context** before coding: is this a research/ML project, a systems project (C/C++/Cython), or coursework?

---

### Context A: Research & ML (Default)

*Trigger: anything involving PyTorch, JAX, NumPy, scikit-learn, training loops, data pipelines.*

#### Code Style
- **Modular and typed**: Use classes, functions, and type hints on all public APIs. No monolithic scripts over 400 lines.
- **NumPy/tensor conventions**:
  - Always document tensor shapes in docstrings or comments when non-obvious (e.g., `# (B, T, D)`).
  - Prefer `einops` for readable tensor rearrangements over manual `reshape`/`permute`.
  - Use `torch.no_grad()` in inference/evaluation contexts.
- **Reproducibility**: Pin random seeds (`torch.manual_seed`, `np.random.seed`) in training scripts. Log hyperparameters.
- **Configuration**: Use **Hydra + OmegaConf** for ML configuration. Define structured configs with `@dataclass` (no `frozen=True` — Hydra needs mutability for config composition) and access them at runtime as `DictConfig`. No bare `argparse` dicts, no `pydantic` models for config.
- **Logging**: Use Python's `logging` module, not `print`. In ML training, use `tqdm` for progress and a proper experiment tracker (W&B, MLflow, or at minimum TensorBoard).
- **Performance**: Profile before optimizing. Use vectorized NumPy/PyTorch ops; avoid Python-level loops over large arrays.
- **Formatting**: `black` + `isort` + `ruff` — configured as pre-commit hooks and run via `pre-commit run`, never invoked directly.

#### Testing
- Tests go in `tests/` mirroring `src/` structure exactly.
- Use `pytest`. Mark slow/GPU tests with `@pytest.mark.slow` so they can be skipped in CI.
- Test data pipelines, preprocessing, and metric computations — not just utility functions.
- For ML models, test output shapes, not just that the forward pass runs.

---

### Context B: Systems & Extensions (C/C++/Cython)

*Trigger: `.cpp`, `.hpp`, `.pyx`, `.pxd`, `setup.py` with extensions, `CMakeLists.txt`.*

#### C/C++ Style
- **C++17 or later** — use structured bindings, `std::optional`, `if constexpr`, range-based for.
- **RAII everywhere**: no raw `new`/`delete`. Use `std::unique_ptr`/`std::shared_ptr` with `make_unique`/`make_shared`.
- **Naming**: `PascalCase` for types, `snake_case` for functions/variables, `kConstant` or `UPPER_SNAKE` for constants, trailing `_` for private members.
- **Formatting**: `clang-format` — no exceptions.
- **Memory safety**: Prefer `std::span`, `std::string_view` over raw pointers for non-owning views.

#### Cython Style
- Always use typed memoryviews (`double[::1]`) over NumPy arrays for performance-critical paths.
- Declare C types with `cdef`; use `cpdef` only when Python access is needed.
- Add `# cython: boundscheck=False, wraparound=False` at the top of performance-critical `.pyx` files only after correctness is verified.
- Test both the Cython extension and a pure-Python fallback if one exists.

---

## III. Writing & Documentation Tone

- **Academic tone for ML**: Concise, precise, active voice. Quality matching a Nature/NeurIPS paper. No filler.
- **No AI accent**: Never use "It is worth noting," "In conclusion," "Let's delve into," "I have successfully," "Certainly!", "Absolutely!".
- **Simple vocabulary**: "use" not "utilize," "fix" not "rectify," "show" not "demonstrate."
- **No EM dash** (—) in writing. Use commas or restructure the sentence.
- Docstrings: Google style for Python. One-line summary, then Args/Returns/Raises sections. Skip trivial getters.

---

## IV. Git & Commits

- **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `perf:`, `docs:`.
- **All lowercase** subject line: `feat: add attention mask support`, not `feat: Add attention mask support`.
- **Never add Claude as co-author.** No `Co-Authored-By: Claude` lines — ever.
- **Never commit if bugs are detected** in the staged diff.
- **Atomic commits**: one logical change per commit. Avoid "WIP" commits on main branches.

---

## V. Error Handling

- **Never silently swallow exceptions.** If catching to add context: `raise NewError("...") from e`.
- **Validate at boundaries**: user input, file I/O, external API responses. Trust internal code.
- **No bare `except: pass`** — this is always wrong.
- In ML training loops: catch and log CUDA OOM errors gracefully; checkpoint before re-raising when possible.

---

## VI. Security Checklist (Before Any Commit)

- No hardcoded API keys, tokens, or passwords — use environment variables.
- No `eval()` or `exec()` on untrusted input.
- No `pickle.load()` from untrusted sources (use `safetensors` or `numpy.load` for model weights).
- Parameterize any SQL queries; never concatenate user input into query strings.

---

## VII. Performance Heuristics

- Profile with `cProfile` / `py-spy` before claiming something is slow.
- NumPy/PyTorch vectorization over Python loops for any array > 1K elements.
- Use `torch.compile` (PyTorch 2.x) for training loops when targeting production throughput.
- Prefer memory-mapped files (`np.memmap`, HuggingFace `datasets`) for datasets that don't fit in RAM.
- In C extensions: minimize Python↔C boundary crossings; batch work in C, return results once.
