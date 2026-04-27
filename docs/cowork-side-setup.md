# Cowork-side setup

Configuring your upstream Claude conversation surface (Cowork / Claude.ai / Claude Desktop / Claude for Work) to emit findings in inbox-ready format by default — so you stop pasting the export prompt at the end of every conversation.

## What this saves

Without per-Project custom instructions, every dispatch requires:

1. Open the inbox file.
2. Copy the export prompt from its header.
3. Paste into the upstream conversation.
4. Wait for the formatted reply.
5. Copy the reply.
6. Paste into the inbox.

With per-Project custom instructions, steps 2–4 disappear. You type "dispatch" in the upstream conversation; the formatted block is the reply.

## Setup

### 1. Decide on your Project layout

Suggested patterns:

- **Single-app project:** one Project named `<Project Name> — Errors`.
- **Multi-app monorepo:** one Project per active app (`<Project Name> — Web errors`, `<Project Name> — API errors`, `<Project Name> — Worker errors`). You don't need them all on day one — start with one or two for whichever apps you actively audit.

Do not create a global "all errors" Project — Project-scoped Custom instructions only work when each Project's identity is narrow.

### 2. Create the Project

In your upstream Claude surface, create a new Project with the name from step 1.

### 3. Paste the custom instructions

Open `~/.claude/cowork-project-instructions.md` (the installer seeded this file). Copy the fenced template block under the "Generic template" heading. Replace `[APP]` with your app's literal name (the same string you'll list in `cowork-config.json` `apps` if you've configured it). Replace `[APP_PURPOSE]` with a one-line description.

Paste the filled-in block into the Project's "Custom instructions" / "Set behaviour" / "System prompt" field. The exact label varies:

- claude.ai web — "Custom instructions" inside Project settings.
- Claude Desktop — "System prompt" inside Project settings.
- Claude for Work — "Behaviour" at the workspace or Project level, depending on how your tenant is configured.

Save.

### 4. (Recommended) Upload Project knowledge

If your upstream surface supports per-Project file uploads, attach:

1. Your project's root `CLAUDE.md` (or equivalent) — repo conventions, mandatory rules.
2. The matching app's `CLAUDE.md` if you have one.
3. Any running known-bugs / issues log.

This grounds the upstream's analysis in real conventions instead of inferring. Reduces back-and-forth.

### 5. Smoke test

Open a chat in the new Project. Paste a real error or describe a small symptom. Once you have one finding, type `dispatch`. The reply should:

- Start with `## <Title>` (no preamble).
- Have `Severity:` and `Apps:` lines below the heading.
- End with `---` on its own line.
- Have no closing remarks or recap after the last finding.

If the format drifts, the custom-instructions text didn't take — re-check the field saved correctly. Some surfaces require an explicit "Apply" button click.

## Per-project enrichment (optional)

If your project has long-running plan trackers (multi-week initiatives with phase / sub-phase status), extend the custom instructions with a *Current build state* section that lists what is shipped vs deferred. This stops the upstream from proposing findings on already-completed or deliberately-deferred work.

Keep that section up to date when the tracker advances. If you forget for a few weeks, the upstream will start suggesting fixes for things that have already shipped — annoying but harmless.

## Maintenance

Refresh the Project knowledge upload when your conventions change materially (new mandatory rule, retired app, added app). The custom-instructions text rarely needs to change — the format rules in the template are stable.
