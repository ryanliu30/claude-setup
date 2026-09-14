---
name: verify-agent-implementation
description: Verify an agent's implementation against its design spec before declaring the task done. Activate after any auto-mode or delegated agent completes a multi-file implementation, after picking up work from a prior session, or when tests pass but runtime behavior feels wrong.
origin: extracted from project practice (2026-05-15)
---

# Verifying Agent Implementation Against Design Spec

## When to Activate

- After an auto-mode or delegated agent implements a design spec.
- Before declaring a multi-file refactor done.
- When tests pass but runtime behavior feels wrong.
- When a new session picks up work from a prior session.

---

## Common Failure Modes

- **Old pipeline left in place**: new code added beside the old; the old path still wins because the router, factory, or import was never updated.
- **Wrong location or language**: spec says "Cython extension in `simulation/`"; agent wrote pure Python in `utils/`.
- **Wrong encoding or schema**: spec defines a new format; agent kept the old one. Downstream readers produce garbage.
- **Banned dependency not removed**: `from legacy_lib import Foo` still present.
- **Partial API migration**: signature updated, call sites not. Unit tests pass, integration breaks.
- **Tests patched to match wrong code**: tests rewritten to fit the bad implementation.
- **Config key mismatch**: spec renames `learning_rate` to `lr`; the loader or YAML still uses the old key, so the old default takes effect.
- **Silent no-op registration**: handler class written, `register()` call missing.
- **Feature flag not wired**: behavior implemented, flag check not, so the change is always on.
- **Incomplete deletion**: function deleted, but the import, CLI entrypoint, or route that calls it remains.
- **Wrong abstraction level**: spec says move logic to a base class; agent duplicated it in two subclasses.
- **Async/sync boundary ignored**: definition changed, callers not; fails only under concurrency.
- **Environment-specific assumption**: hardcoded path, port, or credential that works locally only.

---

## Step 1: Read the Spec End-to-End

Read the whole spec before any code. Build a checklist:

- Function and class names that must exist
- Function and class names that must be deleted
- Imports to add and remove
- Data types at every API boundary
- Config fields, CLI flags, and environment variables that changed
- Explicit "must not" constraints: banned dependencies, banned encodings, module boundaries

---

## Step 2: Map Every Spec Requirement to Code

For each file the spec mentions:

```bash
# Banned imports
grep -rn "from legacy_lib\|import legacy_lib" src/

# Function exists with the right signature
grep -n "def function_name" path/to/file.py

# Old code deleted, not commented out
grep -n "old_function\|OldClass" path/to/file.py

# Registration or wiring call present
grep -n "register\|add_route\|subscribe" path/to/file.py

# Config keys match the spec
grep -rn "old_key_name" configs/
```

Where the spec prescribes internal logic (encoding, algorithm, data structure, registry wiring),
read the lines, not just the grep output.

---

## Step 3: Classify Every Deviation by Severity

| Severity | Criterion | Example |
|----------|-----------|---------|
| CRITICAL | Wrong runtime behavior; corrupt or invalid output | Old encoding kept; new reader gets garbage |
| CRITICAL | Banned dependency present; fails on target environment | Legacy import survives in production code |
| CRITICAL | Wrong module boundary; consumers import from the wrong place | Extension left as pure Python in the wrong package |
| CRITICAL | Silent no-op; component never registered or called | Handler class exists but `register()` never called |
| MODERATE | Partial API migration; integration breaks, unit tests pass | Signature updated, call sites not |
| MODERATE | Config key mismatch; old default wins | Renamed field not updated in loader or YAML |
| MODERATE | Async/sync boundary violated; fails under concurrency | `await` missing at call site |
| MINOR | Unused import; no runtime effect | Stale import from removed module |
| MINOR | Dead code path still reachable; no functional impact yet | Function deleted, entrypoint left |

---

## Step 4: Build a Dependency-Ordered Fix List

Order fixes so each is unblocked when reached:

1. New modules or extensions
2. Source files exporting the new API
3. Consumer files
4. Config files and registration or wiring code
5. Tests

A circular dependency is a design problem. Raise it rather than patching around it.

---

## Step 5: Record Deviations Before Fixing

Enter plan mode and record each deviation:

- File path and line numbers
- What is wrong, quoting the code
- What the spec requires, quoting the spec
- Severity
- Which other fixes it blocks or depends on

---

## Step 6: Fix in Dependency Order

- One deviation per edit pass.
- After each CRITICAL fix, run the narrowest test:

```bash
conda run -n <env> pytest tests/<affected_module>/ -x -q
```

- After all fixes, run the full suite with coverage:

```bash
conda run -n <env> pytest --cov=src --cov-fail-under=80 -q
```

- Re-run the banned-import grep:

```bash
grep -rn "from legacy_lib\|import legacy_lib" src/
```

---

## When a Deviation Requires a Large Refactor

If the correct fix costs far more than the original implementation, do not expand scope:

- Fix the immediate breakage minimally, for example by updating the test to use existing helpers.
- Add a TODO or project memory note for the larger refactor.
- Report the gap to the user.

---

## Checklist Template

```
Spec: <path to spec document>
Agent output branch/commit: <ref>

[ ] All files listed in spec were touched
[ ] All banned imports removed (grep confirms)
[ ] All deleted functions/classes are gone (grep confirms)
[ ] All new functions have the signature the spec gives
[ ] Data types match at every API boundary
[ ] Encoding/protocol/schema matches spec exactly
[ ] Registration, wiring, and routing calls present for new components
[ ] Config keys and CLI flags match the spec; old keys not active
[ ] Async/sync calling convention consistent across definition and call sites
[ ] Tests updated to match new API, not patched to match wrong code
[ ] Full test suite passes (pytest -q)
[ ] Coverage gate met (--cov-fail-under=80)
```
