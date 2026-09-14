# Common Coding Style

Universal principles, extended by language-specific files.

## Core Mandate

Prefer immutability: create new objects instead of mutating existing ones.

## Design Principles

- Keep implementations simple. Don't optimize prematurely.
- Extract repeated patterns (≥3 occurrences) into reusable functions.
- Build only what's needed now. Refactor when real pressure emerges.

## File Structure

- Target 200–400 lines per file. 800 is the ceiling.
- Organize by feature domain, not by type (e.g., `models/`, not `classes/`).
- Prefer several focused files to one large one.

## Error Handling

- Handle errors at system boundaries: user input, file I/O, external APIs.
- Never silently swallow exceptions. `except: pass` is always wrong.
- Validate all external data; trust internal code and framework guarantees.
- When catching to add context: `raise NewError("...") from e`.

## Naming

- Functions/variables: `snake_case` (Python) or `camelCase` (JS/TS).
- Booleans: `is_`, `has_`, `should_`, `can_` prefix.
- Types/Classes: `PascalCase`.
- Constants: `UPPER_SNAKE_CASE`.

## Red Flags

- Nesting deeper than 4 levels: extract a function.
- Functions over 50 lines: split responsibility.
- Magic numbers: use named constants.
- Mutation of function arguments.

## Comments

No comments by default. Add one only when the WHY is non-obvious: a hidden constraint, a
workaround for a specific bug, a subtle invariant. Never explain WHAT the code does.

## Typing

- Type-hint every function.
- No `Any` or `Optional`. Infer the type from the call sites.
- When more than three types are possible, use a container dataclass or split the method instead
  of a `|` union.

## Documentation

- Every source directory has a README.md summarizing its data flow and public methods.
- After editing a file, update its README if the change affects it.
