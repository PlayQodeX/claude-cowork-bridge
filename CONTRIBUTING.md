# Contributing

Thanks for considering a contribution. This project is small and intentionally so — a single Claude Code skill plus a paste-driven inbox protocol. Most useful contributions are bug reports, doc improvements, and tightening of the skill's parser as real upstream output reveals new shapes.

## Bug reports

Open an issue with:

- The exact upstream output you pasted (redacted as needed).
- What `/cowork` did and what you expected it to do.
- Your platform (OS, shell, Claude Code version if known).

## Pull requests

1. Fork the repo.
2. Create a branch from `main` named `<type>/<short-description>` (`fix/parser-handles-tabs`, `docs/setup-clarification`, `feat/clipboard-watcher`).
3. Make the change. Keep the diff small — this skill earns its weight by being thin.
4. Test the install path on at least one platform: run `install.sh` (or `install.ps1`) into a clean `~/.claude/` and confirm `/cowork` is registered.
5. Update `CHANGELOG.md` under `## [Unreleased]` with one bullet per user-visible change.
6. Open the PR. Reference the issue if there is one.

## Style

- Markdown lines wrap naturally — no fixed column width.
- Skill rules are written as imperative-form bullets (the model reads them).
- User-facing docs are paragraphed prose with bullets only for genuine lists or matrices.
- No emojis in skill files or doc files.

## What this project is NOT

- An app, a service, a CLI binary, or a long-running process. It is configuration files and a skill description. Keep it that way.
- A replacement for Claude Code's native primitives (`/schedule`, `/loop`, sub-agents). It fills the cross-surface gap they don't address.
- An opinionated framework. Project rules come from the user's `CLAUDE.md`, not from this skill.

If a proposed change pulls the project away from any of these, it probably belongs in a different repo.
