# Git Workflow

> **Submodules are read-only.** Never edit files inside a submodule directory.
> If a fix requires a submodule change, stop and report it to the user.

## Commit Message Format

```
<type>(<optional scope>): <lowercase description>

<optional body, wrap at 72 chars>
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `perf`, `docs`, `ci`

Rules:
- Subject line is lowercase and ≤72 chars.
- Body explains *why*, not *what*.
- **Never** add `Co-Authored-By: Claude` or any AI attribution.
- Do not commit if a bug check finds issues.
- One logical change per commit. No WIP commits on main branches.

## Branch Naming

```
feat/<short-description>
fix/<issue-or-description>
exp/<experiment-name>       # for ML experiments
```

## Plan Mode Work Happens in a Worktree

Work under an approved plan runs in a git worktree, never on the user's current branch. This
covers both `/plan` and plan mode entered directly.

Create the worktree right after the plan is approved and before the first edit. Use the harness
worktree tool if available, otherwise:

```bash
git worktree add ../<repo>-<branch> -b feat/<short-description>
```

Do not merge, push, or open a PR when the work finishes. Report and stop.

The branch is finished when it is merge-ready:

- Every change is committed. `git status --porcelain` in the worktree prints nothing.
- No scratch files, debug output, or generated artifacts remain, tracked or untracked.
- `pre-commit run --all-files` and the test suite pass.
- The branch is rebased on the base branch, so the merge is a fast-forward.
- The final report names the branch, the worktree path, and the exact merge command.

On the user's go-ahead, merge and tear down the worktree in the same turn:

1. Leave the worktree session, keeping the branch. A worktree cannot be removed while it is the
   working directory.
2. Merge from the main checkout: `git merge --ff-only <branch>`.
3. `git worktree remove <path>`.
4. `git branch -d <branch>`. Never `-D`.

Confirm: `git worktree list` shows only the main checkout and `git status --porcelain` prints
nothing.

## Pull Request Workflow

1. Read the full commit history (`git diff [base]...HEAD`), not just the latest commit.
2. Draft a PR summary: what changed, why, and what was tested.
3. Include a test plan checklist.
4. Push with `-u` on new branches.

## ML Experiment Branches

- Use `exp/<name>` branches for exploratory work. Merge only when results are validated.
- Tag model checkpoints with `git tag v<version>-<metric>` (e.g., `v1.2-acc92.3`).
- Log hyperparameters in the commit message body or in a `config.yaml` committed alongside results.
