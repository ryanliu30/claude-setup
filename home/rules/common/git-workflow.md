# Git Workflow

> **Submodules are read-only.** Never edit files inside a submodule directory.
> If a fix requires a submodule change, stop and report it to the user instead.


## Commit Message Format

```
<type>(<optional scope>): <lowercase description>

<optional body, wrap at 72 chars>
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `perf`, `docs`, `ci`

Rules:
- Subject line is lowercase and ≤72 chars.
- Body explains *why*, not *what* (the diff shows what).
- **Never** add `Co-Authored-By: Claude` or any AI attribution.
- Do not commit if a bug check finds issues.

## Branch Naming

```
feat/<short-description>
fix/<issue-or-description>
exp/<experiment-name>       # for ML experiments
```

## Plan Mode Work Happens in a Worktree

Any work carried out under an approved plan runs in a git worktree, never on the branch the user
is sitting on. This covers both entry points, `/plan` and plan mode entered directly.

Creating the worktree is the first action after the plan is approved and before the first edit.
While still planning, only the plan file is written, so no worktree exists yet. Use the harness
worktree tool if one is available, otherwise:

```bash
git worktree add ../<repo>-<branch> -b feat/<short-description>
```

Merging is the user's call. Do not merge, push, or open a PR when the work finishes. Report and
stop.

Finishing means the branch is **merge-ready**, so that when the user says merge, the only
remaining action is the merge command itself:

- Every change is committed. `git status --porcelain` in the worktree prints nothing.
- No scratch files, debug output, or generated artifacts are left tracked or untracked.
- `pre-commit run --all-files` passes, and the test suite passes.
- The branch is rebased on the current base branch, so the merge is a fast-forward with no
  conflicts to resolve.
- The final report names the branch, the worktree path, and the exact merge command to run.

On the user's go-ahead, tear the worktree down in the same turn as the merge. Leaving a stale
worktree or a merged branch behind counts as unfinished work.

1. Leave the worktree session first, keeping the branch. A session created by the harness
   worktree tool is pinned inside the worktree and cannot run the merge from the main checkout,
   and a worktree cannot be removed while it is the working directory.
2. Merge from the main checkout: `git merge --ff-only <branch>`.
3. `git worktree remove <path>`.
4. `git branch -d <branch>`. Use `-d`, never `-D`, so git refuses if the branch did not actually
   merge.

Then confirm the teardown: `git worktree list` shows only the main checkout and
`git status --porcelain` prints nothing.

## Pull Request Workflow

1. Analyze full commit history (`git diff [base]...HEAD`), not just the latest.
2. Draft a PR summary: what changed, why, and what was tested.
3. Include a test plan checklist.
4. Push with `-u` flag on new branches.

## ML Experiment Branches

- Use `exp/<name>` branches for exploratory work. Merge only when results are validated.
- Tag model checkpoints with `git tag v<version>-<metric>` (e.g., `v1.2-acc92.3`).
- Log hyperparameters in the commit message body or as a `config.yaml` committed alongside results.
