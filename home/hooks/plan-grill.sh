#!/usr/bin/env bash
# UserPromptSubmit hook: reassert the grill-first rule whenever plan mode is active.
#
# Skill descriptions alone left `grilling` firing only some of the time in plan mode, and no
# hook event fires on a permission-mode change, so shift+tab cannot be caught directly.
# UserPromptSubmit is the one event that carries permission_mode and can inject context, and it
# fires on the first prompt after the switch, which covers /plan and shift+tab alike.
#
# `if` is only evaluated on tool events, so the mode test has to live here rather than in the
# hook entry. Plain stdout on exit 0 is injected as context, which avoids escaping the message
# into JSON.
set -euo pipefail

grep -Eq '"permission_mode"[[:space:]]*:[[:space:]]*"plan"' || exit 0

cat <<'EOF'
Plan mode is active, so the grill-first rule in rules/common/planning.md applies to this prompt.

The `grilling` skill runs to completion before any part of the plan is written. Invoke it now if
it is not already running, and keep working its rounds until the frontier is empty and the user
has confirmed shared understanding. Research the codebase for facts the questions need; the
decisions themselves go to the user through AskUserQuestion.

Two cases where you write the plan instead: the user has said to skip the grilling, or the
grilling is already finished and shared understanding is confirmed. If the frontier is empty on
the first pass because the task has nothing to decide, say so in one line rather than skipping
silently.
EOF
