# FAQ

## Why isn't this just a Claude Code skill in the official skill registry?

Because the value lives in the cross-surface bridge — Cowork → inbox → Claude Code — and the bridge requires user-side glue (the inbox file, the archive folder, optional config) that an official skill couldn't ship without making assumptions about every user's project layout. The skill is tiny on its own; the value is the contract between the skill, the inbox, and the upstream conversation's Project setup.

## Does this work with claude.ai? Claude Desktop? Claude for Work? Cowork specifically?

Yes to all of them. The skill itself doesn't talk to the upstream surface. You paste from wherever, into the inbox file. The `cowork` name is historical — the skill works with any Claude conversation surface that emits text you can copy.

## Can the upstream Claude write directly to the inbox without me pasting?

Not natively. A browser-based Claude can't touch your filesystem. Three realistic options to remove the paste step, in order of effort:

1. **Project-level custom instructions** — automate the format only, paste still happens manually. ~5 minutes per Project. See [cowork-side-setup.md](cowork-side-setup.md).
2. **Clipboard watcher** — a small background script that detects inbox-shaped clipboard content and auto-appends to the inbox. ~30 minutes to build. Not shipped here yet.
3. **MCP server bridge** — an outbound MCP tool the upstream Claude calls directly. Hours to build. Only works if your upstream supports outbound MCP.

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
