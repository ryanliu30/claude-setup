---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**: refactors that turn shallow modules into deep ones, for testability and navigability.

- The **Vocabulary** section below is the architecture language. Use those terms exactly; never "component," "service," "API," or "boundary."
- `CONTEXT.md` names the domain; ADRs in `docs/adr/` record decisions not to reopen. Call the Skill tool with "domain-modeling" when either needs writing or sharpening.

## Vocabulary

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface.

**Module**: anything with an interface and an implementation, at any scale: a function, class, package, or tier-spanning slice. _Avoid_: unit, component, service.

**Interface**: everything a caller must know to use the module correctly: type signature, invariants, ordering constraints, error modes, required configuration, performance characteristics. _Avoid_: API, signature.

**Implementation**: the code inside a module. Distinct from **adapter**: a Postgres repo is a small adapter with a large implementation, an in-memory fake the reverse. Say "adapter" when the seam is the topic, "implementation" otherwise.

**Depth**: how much behaviour a caller or test exercises per unit of interface learned. **Deep**: much behaviour behind a small interface. **Shallow**: the interface is nearly as complex as the implementation.

**Seam** (Michael Feathers): a place where behaviour can be altered without editing there; where a module's interface lives. Seam placement is a separate decision from what goes behind it. _Avoid_: boundary.

**Adapter**: a concrete thing that satisfies an interface at a seam. Names the role, not the contents.

**Leverage**: what callers get from depth. One implementation pays back across N call sites and M tests.

**Locality**: what maintainers get from depth. Change, bugs, knowledge, and verification concentrate in one place.

Principles:

- **Depth is a property of the interface, not the implementation.** A deep module may be built from small swappable parts behind **internal seams** (private, used by its own tests) as well as the **external seam** at its interface.
- **The deletion test.** Delete the module in your head. If complexity vanishes, it was a pass-through. If it reappears across N callers, the module was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. Wanting to test past the interface means the module is the wrong shape.
- **One adapter is a hypothetical seam, two adapters a real one.** No seam unless something varies across it.
- **Accept dependencies, don't create them; return results instead of mutating.** Both shrink the interface and make tests natural.

## Process

### 1. Explore

**Scope before you scan.** Deepening pays off where code keeps changing, so weight recently changed areas:

- If the user named a direction (a module, a subsystem, a pain point), take it.
- Otherwise, read `git log --oneline` for the hot spots, the files and areas that keep coming up, and start there. If changes are scattered, widen the net.

Read `CONTEXT.md` and the ADRs for the area first.

Then spawn a sub-agent to walk the codebase and note friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow**, with an interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything that looks shallow: would deleting it concentrate complexity, or just move it? Concentration is the signal.

### 2. Present candidates as an HTML report

Write a self-contained HTML file to `$TMPDIR` (fallback `/tmp`) as `architecture-review-<timestamp>.html`. Open it (`open <path>` on macOS, `xdg-open <path>` on Linux) and give the user the absolute path.

The report uses **Tailwind via CDN** for styling and **Mermaid via CDN** for graph-shaped diagrams (call graphs, dependencies, sequences). Use hand-built divs and SVG for the rest (mass diagrams, cross-sections, collapse animations). Each candidate gets a **before/after visualisation**.

For each candidate, render a card with:

- **Files**: the files and modules involved
- **Problem**: the friction
- **Solution**: what changes, in plain English
- **Benefits**: in terms of locality, leverage, and how tests improve
- **Before / After diagram**: side by side, showing the shallowness and the deepening
- **Recommendation strength**: `Strong`, `Worth exploring`, or `Speculative`, as a badge

End with a **Top recommendation** section: which candidate to tackle first and why.

**`CONTEXT.md` vocabulary for the domain, the Vocabulary section for the architecture.** If `CONTEXT.md` defines "Order," write "the Order intake module," not "the FooBarHandler" or "the Order service."

**ADR conflicts**: surface a candidate that contradicts an ADR only when the friction justifies reopening the ADR, and mark it in the card: _"contradicts ADR-0007, but worth reopening because…"_.

See [HTML-REPORT.md](HTML-REPORT.md) for the full HTML scaffold, diagram patterns, and styling guidance.

Do not propose interfaces yet. After writing the file, ask: "Which of these would you like to explore?"

### 3. Grilling loop

When the user picks a candidate, call the Skill tool with "grilling" to walk the decision tree: constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Update the domain model inline as decisions settle, through the Skill tool with "domain-modeling":

- **Deepened module named after a concept not in `CONTEXT.md`?** Add the term. Create the file if needed.
- **Fuzzy term sharpened in conversation?** Update `CONTEXT.md` there.
- **Candidate rejected for a lasting reason?** Offer an ADR: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Skip ephemeral reasons ("not worth it right now") and self-evident ones.
- **Exploring alternative interfaces?** Write out the problem space first: the constraints a new interface must satisfy, the dependencies it leans on, a rough code sketch. Then spawn 3 or more sub-agents in parallel, each under a different constraint: minimize the interface (1 to 3 entry points); maximise flexibility; optimise for the most common caller. Brief each with this vocabulary and the `CONTEXT.md` terms; ask for the interface, a usage example, what the implementation hides, the adapters at the seam, and where leverage is thin. Present the designs one at a time, compare them on depth, locality, and seam placement, then recommend one.
