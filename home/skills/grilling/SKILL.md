---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round, then wait for the user's answers before the next round.

## Ask through the question tool

Put every frontier question to the user with the `AskUserQuestion` tool, never as prose in your reply. Do not number questions or print them yourself; the tool renders them.

Per call:

- Up to 4 questions. If the frontier is wider than 4, issue back-to-back calls until the round is exhausted, splitting on topic rather than asking a partial round and moving on.
- 2 to 4 options each, mutually exclusive unless you set `multiSelect: true`.
- Your recommended answer is the **first** option, labelled `... (Recommended)`. This replaces the `➡️` line the old format used.
- `header` is the decision's name in 12 characters or fewer, for example `Storage`, `Auth model`, `Test level`.
- `description` on each option states the consequence of picking it, not a restatement of the label. Name the trade-off the user is accepting.
- Use `preview` when the options are concrete artifacts worth comparing side by side: competing file layouts, API signatures, config shapes, schema sketches. Skip it for plain preference calls.

The user can always answer "Other" with free text, so do not add an escape-hatch option of your own.

## Rounds

Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
