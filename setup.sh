#!/usr/bin/env bash
# Install claude-setup configuration to ~/.claude
# Usage: curl -fsSL https://raw.githubusercontent.com/ryanliu30/claude-setup/main/setup.sh | bash
# Or:    bash setup.sh (from the repo root)

set -e

REPO_URL="https://github.com/ryanliu30/claude-setup"
TARGET="$HOME/.claude"
TMP_DIR=$(mktemp -d)

echo "→ Installing claude-setup to $TARGET"

# If running via curl (no local files), clone first.
# $BASH_SOURCE[0] is empty when piped through bash, but set to the script path
# when invoked directly — so we use it rather than $0 to detect curl-pipe mode.
if [[ -n "${BASH_SOURCE[0]}" && -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/CLAUDE.md" ]]; then
  SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  echo "  Cloning repo to $TMP_DIR..."
  git clone --depth=1 "$REPO_URL" "$TMP_DIR/claude-setup"
  SRC="$TMP_DIR/claude-setup"
fi

mkdir -p "$TARGET/commands" "$TARGET/rules/common" "$TARGET/rules/python" "$TARGET/rules/cpp" "$TARGET/skills"

# Core files
cp "$SRC/CLAUDE.md"      "$TARGET/CLAUDE.md"
cp "$SRC/settings.json"  "$TARGET/settings.json"

# Commands
cp "$SRC/commands/"*.md  "$TARGET/commands/"

# Rules
cp "$SRC/rules/common/"*.md   "$TARGET/rules/common/"
cp "$SRC/rules/python/"*.md   "$TARGET/rules/python/"
cp "$SRC/rules/cpp/"*.md      "$TARGET/rules/cpp/"

# Skills
cp "$SRC/skills/"*.md         "$TARGET/skills/"

# Cleanup temp dir if used
[ -d "$TMP_DIR/claude-setup" ] && rm -rf "$TMP_DIR"

# ponytail plugin — minimalist coding mode (marketplace reference, defaults to lite).
# Non-fatal: skip cleanly if the claude CLI or node is unavailable.
if command -v claude >/dev/null 2>&1; then
  command -v node >/dev/null 2>&1 || echo "  ⚠ node not found — ponytail hooks will no-op until node is installed"
  echo "→ Installing ponytail plugin"
  claude plugin marketplace add DietrichGebert/ponytail || echo "  ⚠ ponytail marketplace add failed — skipping"
  claude plugin install ponytail@ponytail || echo "  ⚠ ponytail install failed — skipping"
else
  echo "  ⚠ claude CLI not found — skipping ponytail plugin (install later: claude plugin install ponytail@ponytail)"
fi

echo "✓ Done. Files installed to $TARGET"
echo ""
echo "  CLAUDE.md   → global guidelines"
echo "  settings.json → permissions + hooks"
echo "  commands/   → /commit /check /plan /code-review /python-review /cpp-review /build-fix /learn /test-coverage"
echo "  rules/      → coding standards for Python, C++, and common practices"
echo "  ponytail    → minimalist coding plugin (defaults to lite; toggle with /ponytail)"
echo ""
echo "  Tip: keep ~/.claude as a git repo and push changes to sync across machines."
