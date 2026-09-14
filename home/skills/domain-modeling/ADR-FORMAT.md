# ADR Format

ADRs live in `docs/adr/` with sequential numbering: `0001-slug.md`, `0002-slug.md`. Create the
directory at the first ADR.

## Template

```md
# {Short title of the decision}

{1-3 sentences: the context, the decision, and why.}
```

An ADR can be a single paragraph. It records *that* a decision was made and *why*.

## Optional sections

Add only when they carry information. Most ADRs need none.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`): when
  decisions get revisited.
- **Considered Options**: when the rejected alternatives are worth remembering.
- **Consequences**: when downstream effects are non-obvious.

## Numbering

Highest existing number in `docs/adr/` plus one.

## When to offer an ADR

All three must hold:

1. **Hard to reverse.**
2. **Surprising without context**: a future reader will look at the code and ask why.
3. **A real trade-off**: there were alternatives and one was picked for specific reasons.

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices with lock-in.** Database, message bus, auth provider, deployment target. Only the ones that would take a quarter to swap.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." Explicit no-s count as much as yes-s.
- **Deliberate deviations from the obvious path.** "Manual SQL instead of an ORM because X." These stop the next engineer from "fixing" it.
- **Constraints not visible in the code.** "No AWS, for compliance." "Response times under 200ms, per the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** Record why REST beat GraphQL, or someone will suggest GraphQL again in six months.
