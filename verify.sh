#!/usr/bin/env bash
# Checks that the config in home/ is actually loadable and that the bugs fixed in this repo
# stay fixed. Run before committing.

set -u
cd "$(dirname "$0")"

fails=0
ok()   { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
check() { if [ "$1" = 0 ]; then ok "$2"; else fail "$2${3:+: $3}"; fi }

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

echo "settings.json"
jq -e . home/settings.json >/dev/null 2>&1
check $? "valid JSON"

overlap=$(jq -r '[.permissions.allow[]] - ([.permissions.allow[]] - [.permissions.deny[]]) | join(", ")' home/settings.json)
[ -z "$overlap" ]
check $? "allow and deny do not overlap" "$overlap"

# The original hook keyed off $CLAUDE_TOOL_INPUT_COMMAND, which does not exist, so it no-opped
# on every Bash call. Commit enforcement is git's now.
! grep -q "CLAUDE_TOOL_INPUT_COMMAND" home/settings.json
check $? "no CLAUDE_TOOL_INPUT_COMMAND (hooks read stdin JSON, not env vars)"

! jq -e '.hooks.PreToolUse' home/settings.json >/dev/null 2>&1
check $? "no PreToolUse hook (git's pre-commit hook enforces commits)"

effort=$(jq -r '.effortLevel // ""' home/settings.json)
case "$effort" in low|medium|high|xhigh|max) ok "effortLevel: $effort" ;;
  *) fail "effortLevel invalid or missing: '$effort'" ;; esac

mode=$(jq -r '.permissions.defaultMode // ""' home/settings.json)
case "$mode" in default|acceptEdits|plan|auto|bypassPermissions) ok "defaultMode: $mode" ;;
  *) fail "permissions.defaultMode invalid or missing: '$mode'" ;; esac

echo "skills"
[ -z "$(find home/skills -maxdepth 1 -name '*.md' -print -quit)" ]
check $? "no flat .md files (Claude Code only discovers <name>/SKILL.md)"

for d in home/skills/*/; do
  name=$(basename "$d")
  if [ ! -f "$d/SKILL.md" ]; then
    fail "$name has no SKILL.md"
  elif ! grep -q "^name:" "$d/SKILL.md" || ! grep -q "^description:" "$d/SKILL.md"; then
    fail "$name/SKILL.md missing name or description frontmatter"
  else
    ok "$name"
  fi
done

echo "commands"
# A file here wins the name and hides the shipped command. Refresh this list when Claude Code
# adds commands; it is the check that caught /plan and /code-review being shadowed.
SHIPPED="plan code-review init run loop schedule simplify security-review design dataviz"
for f in home/commands/*.md; do
  name=$(basename "$f" .md)
  case " $SHIPPED " in
    *" $name "*) fail "$name shadows the shipped /$name" ;;
    *) ok "$name" ;;
  esac
done

echo "single source of truth"
grep -q "cov-fail-under=80" home/rules/common/testing.md
check $? "the coverage gate is stated in rules/common/testing.md"

! grep -qE "RED-GREEN-REFACTOR|cov-fail-under" home/CLAUDE.md
check $? "CLAUDE.md does not restate the TDD rule"

! grep -q "find / -maxdepth" home/CLAUDE.md
check $? "no filesystem scan in the conda protocol"

! diff -q CLAUDE.md home/CLAUDE.md >/dev/null 2>&1
check $? "root CLAUDE.md is not a copy of home/CLAUDE.md (it would load twice in this repo)"

echo "commit command"
grep -q "^model: sonnet$" home/commands/commit.md
check $? "runs on Sonnet, it holds the pre-commit veto"

grep -qi "test suite" home/commands/commit.md
check $? "runs the test suite"

grep -q -- "--no-verify" home/commands/commit.md
check $? "forbids --no-verify"

echo "prose"
offenders=$(grep -rl "—" home/ CLAUDE.md README.md 2>/dev/null | tr '\n' ' ')
[ -z "$offenders" ]
check $? "no em dashes" "$offenders"

echo
if [ "$fails" -eq 0 ]; then
  echo "all checks passed"
else
  echo "$fails check(s) failed"
fi
exit $((fails > 0))
