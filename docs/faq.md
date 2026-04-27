# FAQ

## Why isn't this just a Claude Code skill in the official skill registry?

Because the value lives in the cross-surface bridge — Cowork → inbox → Claude Code — and the bridge requires user-side glue (the inbox file, the archive folder, optional config) that an official skill couldn't ship without making assumptions about every user's project layout. The skill is tiny on its own; the value is the contract between the skill, the inbox, and the upstream conversation's Project setup.

## Does this work with claude.ai? Claude Desktop? Claude for Work? Cowork specifically?

Yes to all of them. The skill itself doesn't talk to the upstream surface. Findings flow into the inbox file from wherever, by whatever transport you set up. The `cowork` name is historical — the skill works with any Claude conversation surface that emits text.

## How does the upstream Claude actually get findings into the inbox?

The skill consumes the inbox file; the inbox is the contract. How it gets populated is upstream of the skill and is your choice. Three common shapes, in order of effort:

1. **Manual paste** — at the lightest, copy the upstream's formatted reply, paste below the `---` in `~/.claude/cowork-inbox.md`. Zero infrastructure. Fine for occasional use.
2. **Clipboard watcher** — a small background script that detects inbox-shaped clipboard content and auto-appends to the inbox. The upstream Claude returns the formatted block on `dispatch`; the watcher catches the copy and writes the file. ~30 minutes to build, removes the paste step entirely.
3. **MCP server bridge** — an outbound MCP tool the upstream Claude calls directly. Hours to build. Only works if your upstream surface supports outbound MCP.

This repo ships the skill (the inbox consumer). It does not ship a transport — pick whichever fits your workflow. For most users, **Project-level custom instructions in the upstream** ([cowork-side-setup.md](cowork-side-setup.md)) plus a clipboard watcher is the sweet spot: the upstream emits inbox-ready format on demand, the watcher writes to the file, and you only ever interact with `/cowork` in Claude Code.

## What if the parser doesn't handle my upstream's output?

The parser is intentionally lenient and tries four shapes in order: `##` headings, `---` separators, numbered list items, single-block fallback. If none match cleanly, the skill tells you what it parsed and asks for guidance — it never silently drops findings.

If you find a shape it consistently mishandles, open an issue with a redacted sample and the expected split. Tightening the parser is a one-line edit to `SKILL.md`.

## What if a finding fails halfway through a batch?

The batch aborts immediately. The failing finding stays in the inbox un-archived. The aggregate report tells you what was completed before the failure and what is left. You fix the underlying issue, then run `/cowork` again — it will skip the already-archived findings and resume on the failed one.

## Why does the skill pause for risk-flagged findings even in auto mode?

Data destruction is irreversible. Every other guardrail in the skill can be disabled or worked around; this one cannot. If a finding's body mentions `DELETE`, `TRUNCATE`, `DROP`, `RESET`, `deleteMany`, `migrate reset`, `db push --force-reset`, or `UPDATE` of historical rows, the skill stops and asks per finding. Auto mode does not lower this bar.

## Can I rename the slash command?

Yes. Rename `~/.claude/skills/cowork/` to whatever you prefer (`~/.claude/skills/dispatch/`, `~/.claude/skills/inbox/`, etc.). Edit the `name:` field in the frontmatter at the top of `SKILL.md` to match. The slash command updates automatically.

## Does this work on Windows?

Yes. The installer ships both `install.sh` (Bash / Git Bash) and `install.ps1` (PowerShell). The skill itself is plain markdown — no platform-specific code. The only Windows-specific note is that `TZ='Asia/Bangkok' date` and similar timezone-environment-variable approaches don't work in some Git Bash distributions; the skill documents the workaround inline.

## What happens to findings after they're archived?

They live forever in `~/.claude/cowork-archive/YYYY-MM-DD_<slug>.md`. The skill never deletes archive files. Treat the archive as your audit trail of what got actioned and when.

## Can I run `/cowork` while already in an active task?

Yes, but be aware: the skill registers each finding in `.claude/active-tasks.md` (if your project has one) using session label `cowork-<finding-slug>`. If a finding's claimed paths overlap with another active session, the skill skips it as blocked and continues with the rest of the batch. This is by design — cross-session safety beats throughput.

## What's the lock-in?

Minimal. Three files in `~/.claude/`. Delete the skill folder and the inbox stops working; delete the archive folder and you lose the trail. Nothing is committed to your project repos. Migrating to a different bridge mechanism is a `rm -rf ~/.claude/skills/cowork` away.

## What if Anthropic ships a native cross-surface dispatch?

Retire the skill. The architecture is intentionally trivial to replace; this project should not exist a day longer than the gap it fills.
