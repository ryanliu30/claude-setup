# Git Workflow

## Commit Message Format

```
<type>(<optional scope>): <lowercase description>

<optional body — wrap at 72 chars>
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

## Pull Request Workflow

1. Analyze full commit history (`git diff [base]...HEAD`), not just the latest.
2. Draft a PR summary: what changed, why, and what was tested.
3. Include a test plan checklist.
4. Push with `-u` flag on new branches.

## ML Experiment Branches

- Use `exp/<name>` branches for exploratory work. Merge only when results are validated.
- Tag model checkpoints with `git tag v<version>-<metric>` (e.g., `v1.2-acc92.3`).
- Log hyperparameters in the commit message body or as a `config.yaml` committed alongside results.
