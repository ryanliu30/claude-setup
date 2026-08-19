# Global Agent Guidelines

These guidelines apply to **all workspaces** and interactions. They are opinionated, ML/research-oriented, and designed for professional Python development with occasional C/C++/Cython work.

> **CRITICAL: Submodules are read-only.** Never edit any file inside a submodule directory.
> If a fix requires a submodule change, stop and tell the user. Do not attempt the edit.

> **Precedence.** The `ponytail` skill governs how much code to write, not whether to test it.
> For library code under `src/`, the test rules in `rules/common/testing.md` bind: tests first,
> `tests/` mirrors `src/`, 80% coverage gate. For scripts, notebooks, and exploratory work the
> skill wins, and one assert-based check is enough.

> **Skills** live at `~/.claude/skills/<name>/SKILL.md` and load by name. Reference them by name,
> for example the `tdd-workflow` skill, never by file path.

---

## I. Environment & Execution

### 1. Running Python
1. Run the command with plain `python`, resolved through `PATH`. Do not inspect the environment first.
2. On `ImportError`, `ModuleNotFoundError`, or `python: command not found`, resolve the environment:
   ```bash
   conda env list                     # prints env names and full paths
   <env_path>/bin/python train.py     # no `conda activate`, no `conda run`
   ```
   Pick the environment named in the repo's README install instructions. If none is documented,
   infer it from the project name.
3. If that also fails, stop and tell the user what you tried and which environments exist. Do not
   scan the filesystem for conda, and never fall back to the base environment.

### 2. Pre-commit
- Commit enforcement belongs to git. In any repo with `.pre-commit-config.yaml`, run
  `pre-commit install` once; git then runs the hooks on every commit.
- Never pass `--no-verify`. If the hook blocks a commit, fix the code, not the gate.
- Never invoke `ruff`, `cython-lint`, `black`, `isort`, or other formatters/linters directly as
  shell commands. Run them exclusively through `pre-commit run`.
- If a repo has no pre-commit config, run its test suite manually before committing.

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
- **Configuration**: Use **Hydra + OmegaConf** for ML configuration. Define structured configs with `@dataclass` (no `frozen=True`, Hydra needs mutability for config composition) and access them at runtime as `DictConfig`. No bare `argparse` dicts, no `pydantic` models for config.
- **Logging**: Use Python's `logging` module, not `print`. In ML training, use `tqdm` for progress and a proper experiment tracker (W&B, MLflow, or at minimum TensorBoard).
- **Performance**: Profile before optimizing. Use vectorized NumPy/PyTorch ops; avoid Python-level loops over large arrays.
- **Formatting**: `ruff`, configured as pre-commit hooks and run via `pre-commit run`, never invoked directly.
- **Loose Backward Compatibility**: no backward compatibility requirement when working in research context. Cleanly outline what will break after the implementation of new feature or refactoring, and request user approval if the backward compatibility is crucial (e.g., breaks compatibility with previously generated dataset.)

#### Testing
- Tests go in `tests/` mirroring `src/` structure exactly.
- Use `pytest`. Mark slow/GPU tests with `@pytest.mark.slow` so they can be skipped in CI.
- Test data pipelines, preprocessing, and metric computations, not just utility functions.
- For ML models, test output shapes, not just that the forward pass runs.

---

### Context B: Systems & Extensions (C/C++/Cython)

*Trigger: `.cpp`, `.hpp`, `.pyx`, `.pxd`, `setup.py` with extensions, `CMakeLists.txt`.*

#### C/C++ Style
- **C++17 or later**: use structured bindings, `std::optional`, `if constexpr`, range-based for.
- **RAII everywhere**: no raw `new`/`delete`. Use `std::unique_ptr`/`std::shared_ptr` with `make_unique`/`make_shared`.
- **Naming**: `PascalCase` for types, `snake_case` for functions/variables, `kConstant` or `UPPER_SNAKE` for constants, trailing `_` for private members.
- **Formatting**: `clang-format`, no exceptions.
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
- **No em dashes** in writing. Use commas or restructure the sentence.
- Docstrings: Google style for Python. One-line summary, then Args/Returns/Raises sections. Skip trivial getters.

---

## IV. Git & Commits

- **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `perf:`, `docs:`.
- **All lowercase** subject line: `feat: add attention mask support`, not `feat: Add attention mask support`.
- **Never add Claude as co-author.** No `Co-Authored-By: Claude` lines, ever.
- **Never commit if bugs are detected** in the staged diff.
- **Atomic commits**: one logical change per commit. Avoid "WIP" commits on main branches.
- **Submodules are read-only**: never edit files inside a submodule directory. Raise the change upstream instead.

---

## V. Error Handling

- **Never silently swallow exceptions.** If catching to add context: `raise NewError("...") from e`.
- **Validate at boundaries**: user input, file I/O, external API responses. Trust internal code.
- **No bare `except: pass`**: this is always wrong.
- In ML training loops: catch and log CUDA OOM errors gracefully; checkpoint before re-raising when possible.

---

## VI. Security Checklist (Before Any Commit)

- No hardcoded API keys, tokens, or passwords; use environment variables.
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
