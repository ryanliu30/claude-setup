---
name: verify-agent-implementation
description: Verify an agent's implementation against its design spec before declaring the task done. Activate after any auto-mode or delegated agent completes a multi-file implementation, after picking up work from a prior session, or when tests pass but runtime behavior feels wrong.
origin: extracted from project practice (2026-05-15)
---

# Verifying Agent Implementation Against Design Spec

## When to Activate

- After any auto-mode or delegated agent completes an implementation based on a design spec document.
- Before declaring a multi-file refactor "done" and moving to the next phase.
- When tests pass but runtime behavior feels wrong (partial migration symptom).
- When a new session picks up work from a prior session, always re-verify before continuing.

---

## Common Failure Modes

- **Old pipeline left in place**: new code added alongside the old; old path silently wins at runtime because the router, factory, or import was never updated.
- **Wrong location or language**: spec says "Cython extension in `simulation/`"; agent wrote pure Python in `utils/`. Functionally similar but violates performance and module-boundary requirements.
- **Wrong encoding or schema**: spec defines a new binary format or data schema; agent kept the old one. Downstream readers silently produce garbage.
- **Banned dependency not removed**: `from legacy_lib import Foo` still present after the spec said to remove all legacy dependencies.
- **Partial API migration**: function signature updated, but call sites still use the old signature. Unit tests pass locally; integration breaks.
- **Tests patched to match wrong code**: test suite passes because tests were rewritten to fit the bad implementation, not vice versa.
- **Config key mismatch**: spec renames a config field (`learning_rate` -> `lr`); agent updated the model but not the config loader or YAML files, so the old default silently takes effect.
- **Silent no-op registration**: spec adds a new handler/plugin/strategy to a registry; agent wrote the class but forgot the `register()` call, so it is never invoked.
- **Feature flag not wired**: spec gates behavior behind a flag; agent implemented the behavior but not the flag check, so the change is always-on in production.
- **Incomplete deletion**: spec says to remove a deprecated code path; agent deleted the function but left the import, the CLI entrypoint, or the route that calls it. The dead path is still reachable.
- **Wrong abstraction level**: spec says to move logic into a base class; agent duplicated it in two subclasses instead. Tests pass, but future changes will diverge.
- **Async/sync boundary ignored**: spec changes a function from sync to async (or vice versa); agent updated the definition but left callers using the old calling convention, causing runtime errors only under concurrency.
- **Environment-specific assumption**: agent hardcoded a path, port, or credential that works locally but fails in CI or production.

---

## Step 1: Read the Spec End-to-End First

Read the design spec completely before looking at any code. Build a checklist:

- Exact function/class names that should exist
- Exact function/class names that should be deleted
- Imports that should be added and removed
- Data types flowing in and out at every API boundary
- Config fields, CLI flags, or environment variables that changed
- Any explicit "must not" constraints (banned dependencies, banned encodings, module boundaries)

---

## Step 2: Map Every Spec Requirement to Actual Code

For each file the spec mentions, read the implementation and check:

```bash
# Scan for banned imports
grep -rn "from legacy_lib\|import legacy_lib" src/

# Confirm a function exists with the right signature
grep -n "def function_name" path/to/file.py

# Confirm old code was deleted (not just commented out)
grep -n "old_function\|OldClass" path/to/file.py

# Confirm a registration or wiring call is present
grep -n "register\|add_route\|subscribe" path/to/file.py

# Check config keys match the spec
grep -rn "old_key_name" configs/
```

Read the actual lines, not just grep output, for any file where the spec prescribes specific internal logic (encoding, algorithm, data structure, registry wiring).

---

## Step 3: Classify Every Deviation by Severity

| Severity | Criterion | Example |
|----------|-----------|---------|
| CRITICAL | Wrong runtime behavior; pipeline produces corrupt or invalid output | Old encoding kept; new reader gets garbage |
| CRITICAL | Banned dependency still present; fails on target environment | Legacy import survives in production code |
| CRITICAL | Wrong module boundary; downstream consumers import from wrong place | Extension left as pure Python in wrong package |
| CRITICAL | Silent no-op; new component written but never registered or called | Handler class exists but `register()` never called |
| MODERATE | Partial API migration; integration breaks but unit tests pass | Signature updated, call sites not updated |
| MODERATE | Config key mismatch; old default silently wins | Renamed field not updated in loader or YAML |
| MODERATE | Async/sync boundary violated; fails under concurrency | `await` missing at call site after function went async |
| MINOR | Unused import not cleaned up; does not affect runtime | Stale import from removed module |
| MINOR | Dead code path still reachable via CLI or route; no functional impact yet | Deprecated function deleted but entrypoint left |

---

## Step 4: Build a Dependency-Ordered Fix List

Order deviations so each fix is unblocked when you reach it:

1. New modules or extensions (other files import from them)
2. Source files exporting the new API (before updating consumers)
3. Consumer files (after their dependencies are correct)
4. Config files and registration/wiring code
5. Tests last (after all source is correct)

If a fix depends on another fix, the dependency must come first. Circular dependencies signal a design problem, raise it rather than patching around it.

---

## Step 5: Record Deviations Before Fixing

Enter plan mode and record every deviation with:

- File path and line number(s)
- What is wrong (quote the actual code)
- What the spec requires (quote the spec)
- Severity label
- Which other fixes this one blocks or depends on

This creates a permanent audit trail and prevents losing track under a large diff.

---

## Step 6: Fix in Dependency Order

- Fix one deviation at a time. Do not batch unrelated files into one edit pass.
- After each CRITICAL fix, run the narrowest possible test:

```bash
conda run -n <env> pytest tests/<affected_module>/ -x -q
```

- After all deviations are fixed, run the full suite with coverage:

```bash
conda run -n <env> pytest --cov=src --cov-fail-under=80 -q
```

- Re-run the banned-import grep to confirm constraints are fully satisfied:

```bash
grep -rn "from legacy_lib\|import legacy_lib" src/
```

---

## When a Deviation Requires a Large Refactor

If correctly fixing a deviation requires substantially more work than the original implementation, do not silently expand scope. Instead:

- Fix the immediate breakage minimally (e.g., update the test to use existing helpers rather than rewriting a factory).
- Add a TODO comment or project memory note flagging the larger refactor.
- Report the gap to the user explicitly.

This keeps the corrective pass bounded and the suite green without taking on unbounded scope.

---

## Checklist Template

Copy and fill in when verifying an agent implementation:

```
Spec: <path to spec document>
Agent output branch/commit: <ref>

[ ] All files listed in spec were actually touched
[ ] All banned imports removed (grep confirms)
[ ] All deleted functions/classes are gone (grep confirms)
[ ] All new functions have the correct signature per spec
[ ] Data types match at every API boundary (in/out types)
[ ] Encoding/protocol/schema matches spec exactly
[ ] Registration, wiring, and routing calls are present for new components
[ ] Config keys and CLI flags match the spec; old keys not silently active
[ ] Async/sync calling convention consistent across definition and all call sites
[ ] Tests updated to match new API, not patched to match wrong code
[ ] Full test suite passes (pytest -q)
[ ] Coverage gate met (--cov-fail-under=80)
```
