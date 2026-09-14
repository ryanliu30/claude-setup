---
name: grilling
description: Grill the user about a plan, decision, or idea until every open question is settled. In plan mode, use it only after the user accepts the grilling offer that rules/common/planning.md has the agent make before researching or writing any part of the plan. Also use when the user wants to stress-test their thinking, or says "grill me", "stress-test this", "poke holes in this", "challenge this", or "interview me".
---

Interview the user until you reach a shared understanding. Treat the conversation as a **design
tree**: every decision branches into the decisions that depend on it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are settled:
the questions you can ask now without guessing at unheard answers. Ask the whole frontier in one
round, then wait for the answers.

## Ask through the question tool

Put every frontier question through `AskUserQuestion`, never as prose. Do not number or print
questions yourself.

Per call:

- Up to 4 questions. If the frontier is wider, issue back-to-back calls split by topic until the
  round is exhausted.
- 2 to 4 options each, mutually exclusive unless `multiSelect: true`.
- Your recommended answer is the first option, labelled `... (Recommended)`.
- `header`: the decision's name in 12 characters or fewer, for example `Storage`, `Auth model`,
  `Test level`.
- `description`: the consequence of picking that option and the trade-off accepted, not a
  restatement of the label.
- `preview`: only for concrete artifacts worth comparing side by side: file layouts, API
  signatures, config shapes, schema sketches.

## The user can always type their own answer

The options are suggestions, never a closed list. The user may answer any question in their own
words, through the tool's built-in "Other" or as a plain message instead of a selection. Treat a
typed answer as the decision: record it as given, do not re-ask the question, do not map it onto
the nearest option, and do not push the user back into the option list. Because "Other" is always
there, add no escape-hatch option of your own.

## Rounds

Each round of answers settles decisions and unblocks the questions that depended on them.
Recompute the frontier and ask the next round. A question that depends on another question still
open in this round belongs to a later round.

Facts are your job, decisions are the user's. When a question needs a fact from the environment,
dispatch a sub-agent to find it; never ask the user for anything you can look up. Do not block on
the lookup: only the questions downstream of it wait, ask the rest of the frontier now.

The session is done when the frontier is empty: every branch visited, nothing silently assumed.
Do not act until the user confirms shared understanding.
