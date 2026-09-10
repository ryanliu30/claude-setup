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
- Hooks ship as `home/hooks/<name>.sh`, wired up in `home/settings.json` and installed to
  `~/.claude/hooks`. They are for injecting context, never for gating: commit enforcement is
  git's `pre-commit` hook, because a `PreToolUse` hook cannot reliably gate commits and the
  previous one silently no-opped for months. `verify.sh` fails on any `PreToolUse` entry.
- `plan-grill.sh` is the only hook. It runs on `UserPromptSubmit`, the one event that carries
  `permission_mode` and can inject context, and reasserts the grill-first rule whenever plan
  mode is active. No hook event fires on a mode change, so this is what covers shift+tab.
  A hook's `if` field is evaluated only on tool events, so the mode test lives in the script.
- No em dashes in any shipped markdown. `verify.sh` fails on them.
