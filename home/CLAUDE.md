# Global Agent Guidelines

These guidelines apply to **all workspaces** and interactions. They are opinionated, ML/research-oriented, and designed for professional Python development with occasional C/C++/Cython work.

The standards themselves live in `rules/`: `rules/common/` loads in every session, and `rules/python/` and `rules/cpp/` load when matching files are in play. This file holds only what those rules do not: environment, scope, context switching, and tone.

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
  shell commands. Run them exclusively through `pre-commit run`, for example
  `pre-commit run --all-files` or `pre-commit run --files <paths>`.
- If a repo has no pre-commit config, run its test suite manually before committing.

---

## II. Scope

The request sets the scope, and the scope is the deliverable. A pre-existing bug, a performance
concern, or behavior the task does not mention is a follow-up to report in the summary, not a
change to make, unless the requested behavior cannot work without it. Where the task is ambiguous,
implement the reading its wording and the surrounding code most directly support, state that
assumption, and do not build for the other readings as well. Scratch scripts and quick checks need
not be kept. Commit tests only where the task asks for them or where `rules/common/testing.md`
requires them; for library code under `src/` those rules win.

---

## III. Context

**Check the context** before coding: is this a research/ML project, a systems project (C/C++/Cython), or coursework?

### Context A: Research & ML (Default)

*Trigger: anything involving PyTorch, JAX, NumPy, scikit-learn, training loops, data pipelines.*

`rules/python/` governs style, Hydra configuration, logging, and tests. In addition:
- **Reproducibility**: pin random seeds (`torch.manual_seed`, `np.random.seed`) in training scripts and log hyperparameters.
- **Progress and tracking**: `tqdm` for progress, and an experiment tracker (W&B, MLflow, or at minimum TensorBoard).
- **Loose backward compatibility**: none required in a research context. Outline what a change breaks, and request approval when compatibility is crucial, for example with an already-generated dataset.

### Context B: Systems & Extensions (C/C++/Cython)

*Trigger: `.cpp`, `.hpp`, `.pyx`, `.pxd`, `setup.py` with extensions, `CMakeLists.txt`.*

`rules/cpp/coding-style.md` governs: C++17 or later, RAII, `clang-format`, typed memoryviews in Cython.

---

## IV. Writing & Documentation Tone

- **Academic tone for ML**: Concise, precise, active voice. Quality matching a Nature/NeurIPS paper. No filler.
- **No AI accent**: Never use "It is worth noting," "In conclusion," "Let's delve into," "I have successfully," "Certainly!", "Absolutely!".
- **No mannered prose**: say what you mean. When a literal phrase is available, use it instead of a metaphor or flourish.
- **Simple vocabulary**: "use" not "utilize," "fix" not "rectify," "show" not "demonstrate."
- **No em dashes** in writing. Use commas or restructure the sentence.
- Docstrings: Google style for Python. One-line summary, then Args/Returns/Raises sections. Skip trivial getters.
