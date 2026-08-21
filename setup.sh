#!/usr/bin/env bash
# Install claude-setup configuration to ~/.claude
# Usage: curl -fsSL https://raw.githubusercontent.com/ryanliu30/claude-setup/main/setup.sh | bash
# Or:    bash setup.sh (from the repo root)

set -e

REPO_URL="https://github.com/ryanliu30/claude-setup"
TARGET="$HOME/.claude"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "→ Installing claude-setup to $TARGET"

# If running via curl (no local files), clone first.
# $BASH_SOURCE[0] is empty when piped through bash, but set to the script path
# when invoked directly, so we use it rather than $0 to detect curl-pipe mode.
if [[ -n "${BASH_SOURCE[0]}" && -d "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/home" ]]; then
  SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/home"
else
  command -v git >/dev/null 2>&1 || { echo "  ✗ git is required to install via curl" >&2; exit 1; }
  echo "  Cloning repo to $TMP_DIR..."
  git clone --depth=1 "$REPO_URL" "$TMP_DIR/claude-setup"
  SRC="$TMP_DIR/claude-setup/home"
fi

mkdir -p "$TARGET"

# Markdown trees: copy in place. No --delete, it would silently remove commands or skills
# that exist only on this machine; orphans are reported below instead.
for dir in commands rules skills; do
  mkdir -p "$TARGET/$dir"
  cp -R "$SRC/$dir/." "$TARGET/$dir/"
done
cp "$SRC/CLAUDE.md" "$TARGET/CLAUDE.md"

# The repo owns settings.json outright, so it is copied like everything else. Anything set
# through /config (enabledPlugins, extraKnownMarketplaces) is reset on every install.
cp "$SRC/settings.json" "$TARGET/settings.json"

# Report files present in ~/.claude but not in the repo, so they get deleted deliberately.
for dir in commands rules skills; do
  while IFS= read -r rel; do
    [ -e "$SRC/$dir/$rel" ] || echo "  ⚠ orphan: $TARGET/$dir/$rel (not in repo, delete if stale)"
  done < <(cd "$TARGET/$dir" && find . -type f -name '*.md' | sed 's|^\./||')
done

# ponytail ships as skills now, its always-on hooks needed node and no-opped without it.
# Remove a plugin install left behind by an earlier setup.sh. Delete this block once every
# machine has re-run the installer.
if command -v claude >/dev/null 2>&1; then
  claude plugin uninstall ponytail@ponytail >/dev/null 2>&1 && echo "  removed the ponytail plugin, its skills ship in skills/ now"
  claude plugin marketplace remove ponytail >/dev/null 2>&1 || true
fi
rm -f "$TARGET/.ponytail-active"

echo "✓ Done. Files installed to $TARGET"
echo ""
echo "  CLAUDE.md   → global guidelines"
echo "  settings.json → permissions (allow/ask/deny), defaultMode, effortLevel, replaces your file"
echo "  commands/   → /commit /check /ml-review /python-review /cpp-review /build-fix /learn /test-coverage"
echo "  rules/      → coding standards for Python, C++, and common practices"
echo "  skills/     → <name>/SKILL.md, loaded on demand by name (includes /ponytail, defaults to lite)"
echo ""
echo "  Commit enforcement is git's. In each repo: pre-commit install"
echo "  To register it in every future clone automatically:"
echo "    pre-commit init-templatedir -t pre-commit ~/.git-template"
echo "    git config --global init.templateDir ~/.git-template"
