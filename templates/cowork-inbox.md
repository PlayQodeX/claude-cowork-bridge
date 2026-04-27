# Cowork Inbox

Findings from any Claude conversation surface (Cowork, Claude.ai, Claude Desktop, Claude for Work) land **below the separator at the bottom of this file**. Run `/cowork` in any Claude Code session to crunch through the batch. The transport that fills this file — manual paste, clipboard watcher, MCP tool, or whatever you've wired up — is upstream of the skill and is your choice.

> **Scope:** this inbox is for tactical findings — bugs, lint, security flags, small refactors, type errors, hydration mismatches, single-session error fixes. Strategic plans (multi-week initiatives, full audits) belong in your project's own planning system, not here.

## How `/cowork` runs

1. Reads this inbox, parses findings, classifies as in-scope / cross-repo / out-of-scope / risk-flagged.
2. Shows one summary block, asks for one reply: `go` / `select` / `skip`.
3. On `go` — runs every in-scope finding sequentially, archives each on success, no per-step prompts.
4. Pauses only for risk-flagged findings (anything mentioning `DELETE` / `TRUNCATE` / `DROP` / `RESET` / row-mutating `UPDATE`) — data-safety gate is non-negotiable.
5. Stops on hard failure (typecheck regression, broken build, hook denial). Surfaces what is done and what is left.
6. Emits one aggregate report at the end. Cross-repo follow-up notes stay in this file for the next `/cowork` run from another scope.

## How to format upstream Claude output for this inbox

Paste this prompt at the end of your upstream Claude conversation when you are ready to dispatch the batch:

```
Dump every finding from this conversation as a single markdown block formatted for the Claude Code /cowork inbox. Each finding must:

- Start with `## <Title>` (concise, ≤80 chars).
- Include severity on its own line, exactly: `Severity: CRITICAL | HIGH | MEDIUM | LOW`.
- Name affected apps explicitly using the literal repo / app names from this project. Format: `Apps: app-one, app-two`.
- State the root cause in one short paragraph.
- State the suggested fix in one short paragraph.
- Cite file paths and line numbers wherever possible (relative to the repo root, e.g. `src/components/foo.tsx:42`).
- End with `---` as a separator before the next finding.

If a finding involves data destruction (DELETE, TRUNCATE, DROP, RESET, deleteMany, migrate reset, db push --force-reset, or UPDATE of historical rows), flag it explicitly in the body so the bridge can pause for confirmation.

No preamble, no closing remarks, no recap. Output the findings only, ready to paste verbatim.
```

For richer per-project setup (Project-level custom instructions in your upstream Claude surface), see `~/.claude/cowork-project-instructions.md`.

## End-to-end workflow

1. Have a normal conversation in any Claude surface — describe errors, paste stack traces, share screenshots. Iterate findings until each is sharp.
2. At the end of the conversation, type `dispatch` (or any equivalent phrase your upstream Project recognises). The upstream Claude returns the formatted batch.
3. The batch lands in this file. If you've wired up an inbox transport (clipboard watcher, MCP tool, browser integration), the landing is automatic. If not, paste the formatted block below the `---` at the bottom of this file. Don't rewrite this header either way.
4. Open Claude Code in the project / repo most findings target.
5. Run `/cowork`. Reply `go` to the summary. Walk away.
6. Come back to one aggregate report. Anything left in the inbox is intentional — out-of-scope findings (run `/cowork` from the other scope) or cross-repo follow-ups.

## Auto-detection

The skill auto-detects per finding:

- **Severity** — first match of `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` / `PASS` (case-insensitive).
- **Affected apps** — any app name from `~/.claude/cowork-config.json` (if present) found in the body.
- **Title** — first heading or first non-empty line.
- **Risk-flag** — destructive keywords listed above.

The export prompt above produces output that hits all four cleanly. Freeform text still works — the parser just may not classify findings as precisely.

---

<!-- Paste output below this line. -->
