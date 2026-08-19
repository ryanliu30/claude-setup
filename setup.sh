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

command -v jq >/dev/null 2>&1 || {
  echo "  ✗ jq is required: settings.json is merged, not overwritten." >&2
  echo "    Install it (brew install jq) and re-run." >&2
  exit 1
}

mkdir -p "$TARGET"

# Markdown trees: copy in place. No --delete, it would silently remove commands or skills
# that exist only on this machine; orphans are reported below instead.
for dir in commands rules skills; do
  mkdir -p "$TARGET/$dir"
  cp -R "$SRC/$dir/." "$TARGET/$dir/"
done
cp "$SRC/CLAUDE.md" "$TARGET/CLAUDE.md"

# settings.json is the one file with live state in it (enabledPlugins, extraKnownMarketplaces,
# and anything set through /config). Merge, never clobber.
LIVE="$TARGET/settings.json"
if [ -f "$LIVE" ]; then
  BACKUP="$LIVE.bak.$(date +%Y%m%d%H%M%S)"
  cp -a "$LIVE" "$BACKUP"
  # `*` merges objects recursively and replaces arrays wholesale, which is what we want:
  # repo owns permissions, defaultMode, and effortLevel; the machine keeps everything else.
  # Re-running therefore resets defaultMode and effortLevel to the repo's values.
  jq -s '.[0] * .[1]' "$LIVE" "$SRC/settings.json" > "$TMP_DIR/merged.json"
  mv "$TMP_DIR/merged.json" "$LIVE"
  echo "  settings.json merged (backup: $(basename "$BACKUP"))"
  # A merge cannot delete keys, so any hook the repo stopped shipping survives here.
  stale=$(jq -r --slurpfile repo "$SRC/settings.json" \
    '((.hooks // {}) | keys) - (($repo[0].hooks // {}) | keys) | join(" ")' "$LIVE")
  for h in $stale; do
    echo "  ⚠ hooks.$h in $LIVE is no longer shipped by the repo"
    echo "    remove it:  jq 'del(.hooks.$h)' \"$LIVE\" > t && mv t \"$LIVE\""
  done
else
  cp "$SRC/settings.json" "$LIVE"
fi

# Report files present in ~/.claude but not in the repo, so they get deleted deliberately.
for dir in commands rules skills; do
  while IFS= read -r rel; do
    [ -e "$SRC/$dir/$rel" ] || echo "  ⚠ orphan: $TARGET/$dir/$rel (not in repo, delete if stale)"
  done < <(cd "$TARGET/$dir" && find . -type f -name '*.md' | sed 's|^\./||')
done

# ponytail plugin, minimalist coding mode (marketplace reference, defaults to lite).
# Non-fatal: skip cleanly if the claude CLI or node is unavailable.
if command -v claude >/dev/null 2>&1; then
  command -v node >/dev/null 2>&1 || echo "  ⚠ node not found, ponytail hooks will no-op until node is installed"
  echo "→ Installing ponytail plugin"
  claude plugin marketplace add DietrichGebert/ponytail || echo "  ⚠ ponytail marketplace add failed, skipping"
  claude plugin install ponytail@ponytail || echo "  ⚠ ponytail install failed, skipping"
else
  echo "  ⚠ claude CLI not found, skipping ponytail plugin (install later: claude plugin install ponytail@ponytail)"
fi

echo "✓ Done. Files installed to $TARGET"
echo ""
echo "  CLAUDE.md   → global guidelines"
echo "  settings.json → permissions (allow/ask/deny), defaultMode, effortLevel, merged with your local keys"
echo "  commands/   → /commit /check /ml-review /python-review /cpp-review /build-fix /learn /test-coverage"
echo "  rules/      → coding standards for Python, C++, and common practices"
echo "  skills/     → <name>/SKILL.md, loaded on demand by name"
echo "  ponytail    → minimalist coding plugin (defaults to lite; toggle with /ponytail)"
echo ""
echo "  Commit enforcement is git's. In each repo: pre-commit install"
echo "  To register it in every future clone automatically:"
echo "    pre-commit init-templatedir -t pre-commit ~/.git-template"
echo "    git config --global init.templateDir ~/.git-template"
