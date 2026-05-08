# claude-setup

Personal Claude Code configuration for ML/research Python development with occasional C/C++/Cython work. Inspired by [MauriceDHanisch/claude-setup](https://github.com/MauriceDHanisch/claude-setup), with commands and rules drawn from [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ryanliu30/claude-setup/main/setup.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/ryanliu30/claude-setup
bash claude-setup/setup.sh
```

## What gets installed to `~/.claude/`

| File / Dir | Purpose |
|-----------|---------|
| `CLAUDE.md` | Global guidelines: ML patterns, C++/Cython style, writing tone, git rules |
| `settings.json` | Permissions (allow/ask), hooks |
| `commands/` | Slash commands (see below) |
| `rules/` | Auto-loaded coding standards by language |

## Slash Commands

| Command | Description |
|---------|-------------|
| `/commit` | Analyze staged diff, bug-check, write Conventional Commit |
| `/check` | Run quality checks, auto-fix formatting/lint, report remainder |
| `/plan` | Structure implementation plan, wait for confirmation before coding |
| `/code-review` | Review staged changes or a PR: security, correctness, ML-specific checks |
| `/python-review` | Deep Python static analysis (ruff, mypy, bandit, ML patterns) |
| `/cpp-review` | C++/Cython review: RAII, memory safety, Cython memoryview patterns |
| `/build-fix` | Incrementally fix build/type errors one at a time |
| `/learn` | Extract reusable patterns from the session into skill files |
| `/test-coverage` | Measure coverage, generate tests for under-covered files |

## Skills

Reference guides installed to `~/.claude/skills/`:

| Skill | Description |
|-------|-------------|
| `python-patterns` | Pythonic idioms, type hints, dataclasses, generators, concurrency |
| `python-testing` | pytest fixtures, parametrize, mocking, ML shape checks, GPU marks |
| `cpp-coding-standards` | C++ Core Guidelines — RAII, smart pointers, naming, concurrency |
| `cpp-testing` | GoogleTest/GMock, CMake/CTest, sanitizers, dependency injection |

## Rules (auto-loaded by file path)

```
rules/
  common/         # universal: style, git, testing, security, performance
  python/         # PEP 8, type hints, ML/NumPy conventions, pytest patterns
  cpp/            # C++17 RAII, clang-format, Cython memoryviews
```

## Sync Across Machines

Keep `~/.claude` as a git repo:

```bash
cd ~/.claude
git init
git remote add origin https://github.com/ryanliu30/claude-setup
git add -A
git commit -m "chore: initial setup"
git push -u origin main
```

On other machines, re-run the install command to pull the latest config.

## Customization

- Edit `~/.claude/CLAUDE.md` for project-level overrides (it's loaded globally).
- Add project-specific rules in `.claude/rules/` at the project root — they layer on top of global rules.
- Drop new commands in `~/.claude/commands/` and they're available as `/command-name` instantly.
