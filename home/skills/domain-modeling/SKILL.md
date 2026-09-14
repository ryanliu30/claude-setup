---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when discussing codebase terminology, writing or editing a CONTEXT.md, or recording or editing an ADR.
---

# Domain Modeling

Build and sharpen the project's domain model while designing: challenge terms, invent edge-case
scenarios, and write glossary entries and decisions down as they settle. Reading `CONTEXT.md` for
vocabulary is not this skill. Use it when changing the model.

## File structure

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

A `CONTEXT-MAP.md` at the root means multiple contexts. The map points to each one:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files only when there is something to write: `CONTEXT.md` at the first resolved term,
`docs/adr/` at the first ADR.

## During the session

### Challenge against the glossary

When a term conflicts with `CONTEXT.md`, say so at once. "Your glossary defines 'cancellation'
as X, but you seem to mean Y. Which is it?"

### Sharpen fuzzy language

When a term is vague or overloaded, propose a precise one. "You're saying 'account': do you mean
the Customer or the User?"

### Discuss concrete scenarios

Stress-test domain relationships with specific scenarios that probe the edges and force precise
boundaries between concepts.

### Cross-reference with code

When the user states how something works, check the code. Surface contradictions: "Your code
cancels entire Orders, but you just said partial cancellation is possible. Which is right?"

### Update CONTEXT.md inline

Update `CONTEXT.md` the moment a term is resolved, not in a batch. Format:
[CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` is a glossary and nothing else. No implementation details, specs, or decisions.

### Offer ADRs sparingly

Offer an ADR only when all three hold:

1. **Hard to reverse.**
2. **Surprising without context**: a future reader will ask why.
3. **A real trade-off**: there were alternatives and one was picked for specific reasons.

Format: [ADR-FORMAT.md](./ADR-FORMAT.md).
