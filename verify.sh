#!/usr/bin/env bash
# Checks that the config in home/ is actually loadable and that the bugs fixed in this repo
# stay fixed. Run before committing.

set -u
cd "$(dirname "$0")"

fails=0
ok()   { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }
check() { if [ "$1" = 0 ]; then ok "$2"; else fail "$2${3:+: $3}"; fi }

command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }

echo "settings.json"
# One parse, six values: the allow/deny overlap, effortLevel, defaultMode, attribution.commit,
# attribution.pr, and allow entries that skip the classifier or contradict the linter rule. An unparseable file fails here and leaves them blank, so the checks below
# report against "".
values=$(python3 - <<'PY' 2>/dev/null
import json

settings = json.load(open("home/settings.json"))
permissions = settings["permissions"]
attribution = settings.get("attribution", {})
print(", ".join(sorted(set(permissions["allow"]) & set(permissions["deny"]))))
print(settings.get("effortLevel", ""))
print(permissions.get("defaultMode", ""))
print(attribution.get("commit", "unset"))
print(attribution.get("pr", "unset"))
broad = ("Bash(sed -i", "Bash(echo", "Bash(git add", "Bash(git commit", "Bash(ruff", "Bash(black", "Bash(isort")
print(", ".join(r for r in permissions["allow"] if r in ("Edit", "Read", "Write") or r.startswith(broad)))
PY
)
check $? "valid JSON"

overlap=$(sed -n 1p <<<"$values")
[ -z "$overlap" ]
check $? "allow and deny do not overlap" "$overlap"

# The original hook keyed off $CLAUDE_TOOL_INPUT_COMMAND, which does not exist, so it no-opped
# on every Bash call. Commit enforcement is git's now.
! grep -q "CLAUDE_TOOL_INPUT_COMMAND" home/settings.json
check $? "no CLAUDE_TOOL_INPUT_COMMAND (hooks read stdin JSON, not env vars)"

! grep -q "PreToolUse" home/settings.json
check $? "no PreToolUse hook (git's pre-commit hook enforces commits)"

echo "hooks"
# Every hook settings.json names must exist and be executable, and every shipped hook must be
# wired up. A path typo or a lost +x bit fails silently at runtime, which is how the last hook
# no-opped for months.
python3 - <<'PY2' 2>/dev/null
import json, os, sys

settings = json.load(open("home/settings.json"))
wired = set()
for event, groups in settings.get("hooks", {}).items():
    if event == "PreToolUse":
        sys.exit("PreToolUse is rejected above")
    for group in groups:
        for handler in group.get("hooks", []):
            cmd = handler.get("command", "")
            if "/hooks/" not in cmd:
                continue
            name = cmd.rsplit("/hooks/", 1)[1].strip('"')
            wired.add(name)
            path = os.path.join("home/hooks", name)
            assert os.path.isfile(path), f"{event} points at missing {path}"
            assert os.access(path, os.X_OK), f"{path} is not executable"

shipped = {f for f in os.listdir("home/hooks") if f.endswith(".sh")}
assert shipped == wired, f"shipped {sorted(shipped)} but settings.json wires {sorted(wired)}"
PY2
check $? "every hook exists, is executable, and is wired up in settings.json"

# The mode gate has to be in the script: a hook entry with `if` set never runs on a non-tool
# event like UserPromptSubmit.
! grep -q '"if"' home/settings.json
check $? "no if field on hook entries (only evaluated on tool events)"

printf '%s' '{"permission_mode":"plan"}' | ./home/hooks/plan-grill.sh | grep -q grilling
check $? "plan-grill.sh injects the grill-first rule in plan mode"

[ -z "$(printf '%s' '{"permission_mode":"auto"}' | ./home/hooks/plan-grill.sh)" ]
check $? "plan-grill.sh stays silent outside plan mode"

effort=$(sed -n 2p <<<"$values")
case "$effort" in low|medium|high|xhigh|max) ok "effortLevel: $effort" ;;
  *) fail "effortLevel invalid or missing: '$effort'" ;; esac

mode=$(sed -n 3p <<<"$values")
case "$mode" in default|acceptEdits|plan|auto|dontAsk|bypassPermissions) ok "defaultMode: $mode" ;;
  *) fail "permissions.defaultMode invalid or missing: '$mode'" ;; esac

# The no-co-author rule is enforced by the harness, not only by prose.
[ "$(sed -n 4p <<<"$values")" = "" ] && [ "$(sed -n 5p <<<"$values")" = "" ]
check $? "attribution.commit and attribution.pr are empty strings"

# Bash deny patterns are not a security boundary (head, sed, sh -c all get past them).
# Secrets are protected by Read rules, which also block Edit and Write on the same path.
for rule in 'Read(//**/.env)' 'Read(~/.ssh/**)' 'Read(~/.aws/**)' 'Read(~/.claude/.credentials.json)'; do
  grep -qF "\"$rule\"" home/settings.json
  check $? "deny has $rule"
done

# In auto mode an allow rule skips the classifier, and reads plus in-tree edits are approved
# anyway, so the allow list holds only the test and lint runners we want unclassified.
broad=$(sed -n 6p <<<"$values")
[ -z "$broad" ]
check $? "allow has no bare Edit/Read/Write, sed -i, echo, git add/commit, or ruff/black/isort" "$broad"

echo "skills"
[ -z "$(find home/skills -maxdepth 1 -name '*.md' -print -quit)" ]
check $? "no flat .md files (Claude Code only discovers <name>/SKILL.md)"

[ ! -d home/commands ]
check $? "no commands/ directory (legacy location, skills replace it)"

# A personal skill wins the name and hides the bundled one. Refresh this list when Claude Code
# adds skills; it is the check that caught /plan and /code-review being shadowed.
SHIPPED="plan code-review init run loop schedule simplify security-review design dataviz update-config keybindings-help fewer-permission-prompts claude-api workflow-authoring artifact-design artifact-diagramming artifact-capabilities claude-in-chrome"
for d in home/skills/*/; do
  name=$(basename "$d")
  if [ ! -f "$d/SKILL.md" ]; then
    fail "$name has no SKILL.md"
  elif ! grep -q "^name: $name$" "$d/SKILL.md" || ! grep -q "^description:" "$d/SKILL.md"; then
    fail "$name/SKILL.md missing name (matching the directory) or description frontmatter"
  else
    case " $SHIPPED " in
      *" $name "*) fail "$name shadows the bundled /$name" ;;
      *) ok "$name" ;;
    esac
  fi
done

for name in commit check; do
  grep -q "^disable-model-invocation: true$" "home/skills/$name/SKILL.md"
  check $? "$name is user-invoked only (disable-model-invocation)"
done

# Two independent paths get grilling to fire in plan mode: the description, which is what skill
# selection reads, and plan-grill.sh. rules/common/planning.md alone was not enough.
grep -q "^description:.*plan mode" home/skills/grilling/SKILL.md
check $? "grilling names plan mode in its description (that is what skill selection reads)"

echo "single source of truth"
grep -q "cov-fail-under=80" home/rules/common/testing.md
check $? "the coverage gate is stated in rules/common/testing.md"

! grep -qE "RED-GREEN-REFACTOR|cov-fail-under" home/CLAUDE.md
check $? "CLAUDE.md does not restate the TDD rule"

! grep -qiE "Security Checklist|Performance Heuristics|## .*Error Handling|## .*Git & Commits" home/CLAUDE.md
check $? "CLAUDE.md does not restate rules/common (security, performance, errors, git)"

! grep -q "find / -maxdepth" home/CLAUDE.md
check $? "no filesystem scan in the conda protocol"

# CLAUDE.md says formatters run only through pre-commit; nothing shipped may contradict it.
! grep -rnE '^\s*(ruff|black|isort) ' home/ >/dev/null
check $? "no direct ruff/black/isort invocation outside pre-commit"

! diff -q CLAUDE.md home/CLAUDE.md >/dev/null 2>&1
check $? "root CLAUDE.md is not a copy of home/CLAUDE.md (it would load twice in this repo)"

echo "commit skill"
grep -q "^model: sonnet$" home/skills/commit/SKILL.md
check $? "runs on Sonnet, it holds the pre-commit veto"

grep -qi "test suite" home/skills/commit/SKILL.md
check $? "runs the test suite"

grep -q -- "--no-verify" home/skills/commit/SKILL.md
check $? "forbids --no-verify"

echo "repo hygiene"
! git ls-files --error-unmatch .claude/settings.local.json >/dev/null 2>&1
check $? "settings.local.json is not tracked (personal file)"

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
