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

Everything shipped lives in `home/`, which mirrors `~/.claude` 1:1. Edit `home/`, re-run
`setup.sh`. `settings.json` is merged with `jq` and backed up first, never clobbered, so
`enabledPlugins` and `extraKnownMarketplaces` survive. The repo owns `permissions`,
`defaultMode` (`auto`), and `effortLevel` (`xhigh`), so installing resets those three. No hooks
are shipped.

## What gets installed to `~/.claude/`

| File / Dir | Purpose |
|-----------|---------|
| `CLAUDE.md` | Global guidelines: ML patterns, C++/Cython style, writing tone, git rules |
| `settings.json` | Permissions (allow/ask/deny), `defaultMode`, `effortLevel`, merged into your existing file |
| `commands/` | Slash commands (see below) |
| `rules/` | Coding standards, scoped by file path |
| `skills/` | On-demand reference guides, one directory each |

## Slash Commands

| Command | Description |
|---------|-------------|
| `/commit` | Analyze staged diff, bug-check, run the test suite, write Conventional Commit (Sonnet) |
| `/check` | Run quality checks, auto-fix formatting/lint, report remainder |
| `/ml-review` | ML-aware review of a diff or PR: data leakage, seeding, tensor and metric correctness |
| `/python-review` | Deep Python static analysis (ruff, mypy, bandit, ML patterns) |
| `/cpp-review` | C++/Cython review: RAII, memory safety, Cython memoryview patterns |
| `/build-fix` | Incrementally fix build/type errors one at a time |
| `/learn` | Extract reusable patterns from the session into skill files |
| `/test-coverage` | Measure coverage, generate tests for under-covered files |

No command here shadows a shipped one. `/plan` and `/code-review` are Claude Code's own:
plan mode gates tools read-only and requires explicit approval, which a prompt file cannot do,
and `/code-review` carries the cloud and PR machinery. What was worth keeping from the old
`plan.md` now lives in `rules/common/planning.md`, and the old `code-review.md` became
`/ml-review`. `verify.sh` fails if a command reclaims a shipped name.

## Skills

Installed as `~/.claude/skills/<name>/SKILL.md` and loaded on demand by name. Only the name and
description sit in context until a skill is invoked, which is why binding requirements belong in
`rules/` and step-by-step procedures belong here.

| Skill | Description |
|-------|-------------|
| `tdd-workflow` | RED-GREEN-REFACTOR with git checkpoints and ML test patterns |
| `python-patterns` | Pythonic idioms, type hints, dataclasses, generators, concurrency |
| `python-testing` | pytest fixtures, parametrize, mocking, ML shape checks, GPU marks |
| `cpp-coding-standards` | C++ Core Guidelines, RAII, smart pointers, naming, concurrency |
| `cpp-testing` | GoogleTest/GMock, CMake/CTest, sanitizers, dependency injection |
| `verify-agent-implementation` | Check an implementation against its design spec before calling it done |
| `ponytail` | Minimalism mode: YAGNI, stdlib first, no unrequested abstractions. Defaults to `lite` |
| `ponytail-review` | Review the current diff for over-engineering, one line per finding |
| `ponytail-audit` | Scan the whole repo for complexity to trim, ranked biggest cut first |

The three `ponytail` skills are vendored from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)
(MIT), lightly adapted. The upstream plugin is not installed: its value was a `SessionStart` hook
that switched minimalism on for every session, and that hook needs `node`, so on a machine without
node it no-opped and the plugin did nothing. As skills they need no runtime at all, at the cost of
loading on demand rather than always. `/ponytail` sets the intensity for the session
(`lite`, `full`, `ultra`), and `rules/common/coding-style.md` carries the always-on baseline.
Precedence is stated in `home/CLAUDE.md`: the skill governs how much code to write, and the test
rules still bind for library code under `src/`.

## Rules

```
rules/
  common/         # no frontmatter, always loaded: style, git, testing, security, performance, planning
  python/         # paths: **/*.py, **/*.pyi
  cpp/            # paths: **/*.cpp, **/*.hpp, **/*.cc, ...
```

`common/` loads in every session. `python/` and `cpp/` carry `paths:` globs in their frontmatter
and load only when matching files are in play.

## Commit Enforcement

Git owns it, not Claude Code. A `PreToolUse` hook cannot see the commit reliably and a non-zero
exit other than 2 is treated as advisory, so the previous hook silently passed every commit.

```bash
pre-commit install                                          # once per repo
pre-commit init-templatedir -t pre-commit ~/.git-template   # optional, once per machine
git config --global init.templateDir ~/.git-template        # registers it in future clones
```

`/commit` installs the hook if a `.pre-commit-config.yaml` exists without one, runs the full
test suite, and refuses to commit when either fails. `--no-verify` is denied in
`settings.json`.

## Sync Across Machines

Re-run the install command on each machine. Do not turn `~/.claude` into a git repo: it also
holds session transcripts in `projects/`, `history.jsonl`, `sessions/`, and `telemetry/`, which
is hundreds of megabytes of prompt history one `git add -A` away from being published.

## Customization

- Edit `home/CLAUDE.md` and re-run `setup.sh` to change the global guidelines.
- Add project-specific rules in `.claude/rules/` at a project root, they layer on top of these.
- Drop new commands in `home/commands/` and they are available as `/command-name` after install.
- Run `./verify.sh` after editing `home/settings.json`, `home/commands/commit.md`, or the skill
  layout.
