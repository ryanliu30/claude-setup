# claude-setup, repo instructions

This repo is the source of truth for `~/.claude`. The global guidelines it ships live in
`home/CLAUDE.md`, and they are already loaded from `~/.claude/CLAUDE.md`, so do not restate
them here.

- `home/` mirrors `~/.claude` 1:1. Edit `home/`, then run `bash setup.sh`. Never hand-edit
  `~/.claude`; the next install would silently overwrite it.
- Run `./verify.sh` before committing. It is the only test suite here.
- Skills are directories: `home/skills/<name>/SKILL.md` with `name` and `description`
  frontmatter. A flat `.md` file in `skills/` never loads.
- `home/settings.json` is copied over the live file like every other shipped file, so the repo
  owns all of it and installing resets whatever `/config` wrote (`enabledPlugins`,
  `extraKnownMarketplaces`). The installer needs no JSON tooling; keep it that way.
- The repo ships no hooks. Commit enforcement is git's `pre-commit` hook, not a Claude Code
  hook: a `PreToolUse` hook cannot reliably gate commits and the previous one silently no-opped
  for months. The copy deletes any hook a machine still has.
- No em dashes in any shipped markdown. `verify.sh` fails on them.
