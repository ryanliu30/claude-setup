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

echo "✓ Done. Files installed to $TARGET"
echo ""
echo "  CLAUDE.md   → global guidelines"
echo "  settings.json → permissions + hooks"
echo "  commands/   → /commit /check /plan /code-review /python-review /cpp-review /build-fix /learn /test-coverage"
echo "  rules/      → coding standards for Python, C++, and common practices"
echo ""
echo "  Tip: keep ~/.claude as a git repo and push changes to sync across machines."
