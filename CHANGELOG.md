# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] — 2026-04-28

### Added

- Initial public release of `cowork-bridge`.
- `/cowork` Claude Code skill — paste-driven dispatch from any upstream Claude conversation surface (Cowork, Claude.ai, Claude Desktop, Claude for Work) into Claude Code as actionable tasks.
- Batch-by-default execution: one summary block, one confirmation reply (`go` / `select` / `skip`), then sequential run of every in-scope finding without per-step prompting.
- Lenient parser handling four shapes of upstream output: top-level `##` headings, `---` separators, numbered list items, single-block fallback.
- Four-bucket classifier: in-scope, cross-repo, out-of-scope, risk-flagged. Risk-flagged findings (DELETE / TRUNCATE / DROP / RESET / row-mutating UPDATE) pause for explicit per-finding confirmation regardless of batch mode.
- Optional `~/.claude/cowork-config.json` to declare app names and project roots.
- `~/.claude/cowork-archive/` durable per-finding archive with footer (date, outcome, scopes touched).
- Cross-repo follow-up note pattern — partial in-scope execution + inbox-resident note for the next session in another scope.
- Bash and PowerShell installers (`install.sh`, `install.ps1`) with idempotent copy and non-overwrite of existing user files.
- Cowork-side companion templates: generic `cowork-project-instructions.md` for upstream Project setup; example `cowork-config.json`.
- Documentation: getting started, Cowork-side setup, configuration, FAQ.
