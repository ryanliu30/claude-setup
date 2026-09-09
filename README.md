# claude-setup

Personal Claude Code configuration for ML/research Python development with occasional C/C++/Cython work. Inspired by [MauriceDHanisch/claude-setup](https://github.com/MauriceDHanisch/claude-setup), with skills and rules drawn from [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code).

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
`setup.sh`. `settings.json` is copied over your live file like everything else, so the repo owns
all of it: `permissions`, `defaultMode` (`auto`), `effortLevel` (`high`, the documented starting
point), `attribution` (empty, so no `Co-Authored-By` trailer or PR footer), and installing resets
anything `/config` wrote, such as `enabledPlugins`. No hooks are shipped.

## What gets installed to `~/.claude/`

| File / Dir | Purpose |
|-----------|---------|
| `CLAUDE.md` | Environment, scope, context switching, and tone. The standards live in `rules/` |
| `settings.json` | Permissions (allow/ask/deny), `defaultMode`, `effortLevel`, `attribution`, copied over your file |
| `rules/` | Coding standards, scoped by file path |
| `skills/` | Slash commands and on-demand reference guides, one directory each |

## Permissions

`defaultMode` is `auto`: a classifier reviews each action instead of prompting. Three facts from
the permissions docs shape the lists:

- An `allow` rule resolves before the classifier and skips it, while reads and edits inside the
  working directory are approved anyway. So `allow` holds only the test and lint runners
  (`pytest`, `mypy`, `pre-commit run`, `clang-tidy`, `cppcheck`) and nothing else. No bare
  `Edit`/`Write`/`Read`, no `git commit`, no `sed -i`.
- `ask` rules still prompt in auto mode, so they name the irreversible or outward-facing
  commands: `git push`, `rm`, package installs, `ssh`, `docker`, `gh pr merge`.
- Bash `deny` patterns are not a security boundary: `Bash(cat *.env*)` does nothing about
  `head .env` or `sh -c`. Secrets are protected by `Read(...)` deny rules (`//**/.env`,
  `~/.ssh/**`, `~/.aws/**`, `~/.netrc`, `~/.claude/.credentials.json`, `~/.config/gh/**`),
  which also block `Edit` and `Write` on the same paths. The Bash denies stay as a second layer.
  In user settings a single leading slash anchors at `~/.claude/`, hence the `//` and `~/` forms.

## Skills

Installed as `~/.claude/skills/<name>/SKILL.md` and loaded on demand by name. Only the name and
description sit in context until a skill is invoked, which is why binding requirements belong in
`rules/` and step-by-step procedures belong here. Skills replace the legacy `commands/` layout:
same `/name` invocation, plus frontmatter the flat files never had.

Slash commands, user-invoked:

| Skill | Description |
|-------|-------------|
| `/commit` | Analyze staged diff, bug-check, run the test suite, write Conventional Commit (Sonnet) |
| `/check` | Run quality checks, auto-fix formatting/lint, report remainder (Haiku) |
| `/ml-review` | ML-aware review of a diff or PR: data leakage, seeding, tensor and metric correctness |
| `/python-review` | Deep Python static analysis via pre-commit hooks, bandit, ML patterns |
| `/cpp-review` | C++/Cython review: RAII, memory safety, Cython memoryview patterns |
| `/build-fix` | Incrementally fix build/type errors one at a time |
| `/test-coverage` | Measure coverage, generate tests for under-covered files |

`/commit` and `/check` carry `disable-model-invocation: true`, so Claude never runs them
on its own. The three review skills carry `context: fork` and run in a subagent, so a long review
does not sit in the main context.

Reference skills, loaded by Claude when the description matches:

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
| `grilling` | Interview the user round by round until a plan has no unexamined branches |
| `domain-modeling` | Build and sharpen `CONTEXT.md` and `docs/adr/` as decisions crystallize |
| `improve-codebase-architecture` | Scan for shallow modules, report the candidates as HTML, then grill one |

No skill here shadows a bundled one. `/plan` and `/code-review` are Claude Code's own: plan mode
gates tools read-only and requires explicit approval, which a prompt file cannot do, and
`/code-review` carries the cloud and PR machinery. What was worth keeping from the old `plan.md`
now lives in `rules/common/planning.md`, and the old `code-review.md` became `/ml-review`.
`verify.sh` fails if a skill reclaims a bundled name.

The three `ponytail` skills are vendored from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)
(MIT), lightly adapted. The upstream plugin is not installed: its value was a `SessionStart` hook
that switched minimalism on for every session, and that hook needs `node`, so on a machine without
node it no-opped and the plugin did nothing. As skills they need no runtime at all, at the cost of
loading on demand rather than always. `/ponytail` sets the intensity for the session
(`lite`, `full`, `ultra`), and `rules/common/coding-style.md` carries the always-on baseline.
Precedence is stated in `home/CLAUDE.md`: the skill governs how much code to write, and the test
rules still bind for library code under `src/`.

`grilling`, `domain-modeling`, and `improve-codebase-architecture` are vendored from
[mattpocock/skills](https://github.com/mattpocock/skills), lightly adapted. The upstream
`codebase-design` skill is not installed: `improve-codebase-architecture` was its only consumer
here, so its glossary (module, interface, depth, seam, adapter, leverage, locality) and the
design-it-twice sub-agent pattern are inlined in that skill instead. The HTML report writes to
`$TMPDIR` and opens with the macOS command this setup actually uses.

## Rules

```
rules/
  common/         # no frontmatter, always loaded: style, git, testing, security, performance, planning
  python/         # paths: **/*.py, **/*.pyi
  cpp/            # paths: **/*.cpp, **/*.hpp, **/*.cc, ...
```

`common/` loads in every session. `python/` and `cpp/` carry `paths:` globs in their frontmatter
and load only when matching files are in play. `CLAUDE.md` does not restate them; `verify.sh`
fails if it starts to.

## Commit Enforcement

Git owns it, not Claude Code. A `PreToolUse` hook that reads the stdin JSON and exits 2 can block
a commit, but the one this repo used to ship read a nonexistent environment variable and so
approved every commit for months without anyone noticing. A git hook fails loudly and runs for
every client, not only Claude Code, so it is the better gate.

```bash
pre-commit install                                          # once per repo
pre-commit init-templatedir -t pre-commit ~/.git-template   # optional, once per machine
git config --global init.templateDir ~/.git-template        # registers it in future clones
```

`/commit` installs the hook if a `.pre-commit-config.yaml` exists without one, runs the full
test suite, and refuses to commit when either fails. `--no-verify` and its short form `-n` are
denied in `settings.json`. Formatters and linters run only through `pre-commit run`; nothing
shipped invokes `ruff` directly, and `verify.sh` checks that.

## Sync Across Machines

Re-run the install command on each machine. Do not turn `~/.claude` into a git repo: it also
holds session transcripts in `projects/`, `history.jsonl`, `sessions/`, and `telemetry/`, which
is hundreds of megabytes of prompt history one `git add -A` away from being published.

## Customization

- Edit `home/CLAUDE.md` and re-run `setup.sh` to change the global guidelines.
- Add project-specific rules in `.claude/rules/` at a project root, they layer on top of these.
- Add a skill as `home/skills/<name>/SKILL.md` with `name` and `description` frontmatter; it is
  available as `/name` after install. Add `disable-model-invocation: true` if only you should
  trigger it.
- Run `./verify.sh` after editing `home/settings.json`, `home/skills/commit/SKILL.md`, or the
  skill layout.
