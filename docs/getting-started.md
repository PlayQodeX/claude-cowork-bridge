# Getting started

This guide walks you through your first `/cowork` cycle end to end. Allow ~10 minutes.

## 1. Install the skill

Pick whichever installer matches your shell:

```bash
# Bash / Git Bash on Windows / macOS / Linux
curl -L https://raw.githubusercontent.com/PlayQodeX/claude-cowork-bridge/main/install.sh | bash
```

```powershell
# PowerShell on Windows
irm https://raw.githubusercontent.com/PlayQodeX/claude-cowork-bridge/main/install.ps1 | iex
```

Either installer copies `skills/cowork/SKILL.md` into `~/.claude/skills/cowork/` and seeds `~/.claude/cowork-inbox.md` if it does not already exist. Existing files are never overwritten.

## 2. Verify the skill is registered

Open Claude Code in any project and check the available-skills list. You should see `/cowork` listed alongside the other skills (`/loop`, `/schedule`, etc.). If you don't, re-run the installer and confirm `~/.claude/skills/cowork/SKILL.md` exists.

## 3. (Optional) Tell the skill about your project

Without configuration, every finding is treated as in-scope and the skill cannot tell when a finding targets a different app. To enable scope-detection, create `~/.claude/cowork-config.json`:

```json
{
  "apps": ["web", "api", "worker"],
  "projectRoots": ["/Users/you/code/my-monorepo"]
}
```

See [configuration.md](configuration.md) for the full schema.

## 4. Land a finding in the inbox

The skill reads from `~/.claude/cowork-inbox.md`. Anything that puts findings into that file works — manual paste at the lightest, an automated transport (clipboard watcher, MCP tool, browser integration) for steady state. For a first run, paste this sample finding below the `---` separator at the bottom of the file:

```
## Console.log left in production code
Severity: LOW
Apps: <one of your app names, or omit if unconfigured>

**Root cause:** A debug `console.log` was committed to `src/components/header.tsx` during PR #42 and is now firing on every page render.

**Suggested fix:** Remove the `console.log` at line 17 of `src/components/header.tsx`. Confirm there are no others in the same file before closing.

**Files:**
- `src/components/header.tsx:17` — debug log to remove

---
```

For your real workflow, set up an automated transport once and stop thinking about how findings get into the inbox. The FAQ has a short summary of the common options; see [faq.md](faq.md) under "Can the upstream Claude write directly to the inbox?".

## 5. Run `/cowork`

In Claude Code, `cd` into the project (or app folder if you configured `projectRoots`) and run:

```
/cowork
```

The skill will:

1. Read the inbox and parse the finding.
2. Classify it as in-scope.
3. Show you a one-line summary block.
4. Ask for a reply.

## 6. Reply `go`

The skill will:

1. Apply your project's `CLAUDE.md` rules (active-tasks register, branding, etc. — whatever your project defines).
2. Open the file, find the line, propose the fix.
3. On completion, archive the finding to `~/.claude/cowork-archive/YYYY-MM-DD_console-log-left-in-production-code.md`.
4. Remove it from the inbox.
5. Emit a one-paragraph aggregate report.

## 7. From here

The first real cycle is the verification. Once you trust the parser handles your upstream Claude's output cleanly, the steady-state usage is:

1. Have your conversation in any upstream Claude surface (Cowork, Claude.ai, Claude Desktop, Claude for Work).
2. Type `dispatch` (or any equivalent phrase your Project setup recognises). The upstream Claude returns the formatted batch.
3. The batch lands in `~/.claude/cowork-inbox.md` via your transport — automatic if you've wired one up, manual paste otherwise.
4. `cd` into the right scope, run `/cowork`, reply `go`.

Two setups make this reliable in steady state:

- **Project-level custom instructions** in your upstream Claude — so you stop pasting the export prompt at the end of every conversation. See [cowork-side-setup.md](cowork-side-setup.md). One-time, ~5 minutes per Project.
- **An automated inbox transport** — so step 3 stops being a paste. Common shapes: a clipboard watcher that detects inbox-shaped clipboard content and appends it to the file, an MCP tool the upstream calls directly, or a browser integration. The FAQ summarises trade-offs.
