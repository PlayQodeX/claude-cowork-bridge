---
name: cowork
description: Bridge any Claude conversation surface (Cowork, Claude.ai, Claude Desktop, Claude for Work) into Claude Code as actionable tasks. Reads a global inbox, parses findings, runs them sequentially with one confirmation gate, and archives on completion. Default behaviour is batch mode — fall back to interactive cherry-pick with "select". Honours every rule from the current project's CLAUDE.md automatically. Invoke on /cowork, "triage cowork findings", "burn through the cowork inbox", or "run the next cowork audit item".
---

# /cowork — Conversation-to-code dispatch bridge

This skill is a paste-driven bridge between any Claude conversation surface (where audits, error-fix conversations, and benchmarks happen) and Claude Code (where the fixes are made). The user pastes the upstream conversation's output into a global inbox file; this skill summarises it, gets one confirmation, and burns through every in-scope finding sequentially without per-step prompting.

The skill is **project-agnostic**. It applies whatever rules the current project's `CLAUDE.md` defines (data safety, schema discipline, branding, testing, cross-session coordination) by routing each finding through Claude Code's normal task flow — `CLAUDE.md` rules are loaded automatically. The skill itself enforces only one rule above and beyond that: a non-negotiable pause for findings that mention data-destructive operations.

## Files this skill uses

- **Inbox:** `~/.claude/cowork-inbox.md` — paste destination, never wiped except to remove a single archived finding.
- **Archive:** `~/.claude/cowork-archive/` — auto-created on first archive. One file per completed finding.
- **Optional config:** `~/.claude/cowork-config.json` — declares the user's project's app/repo names so the parser can distinguish in-scope from out-of-scope findings automatically.

The inbox is global (one per user, not per project). It works for monorepos, single-app projects, and unscoped findings — each finding's apps line tells the skill what scope it targets.

## Optional configuration

If `~/.claude/cowork-config.json` exists, the skill reads it for two pieces of information:

```json
{
  "apps": ["app-one", "app-two", "shared-lib"],
  "projectRoots": ["/absolute/path/to/your/project-or-monorepo"]
}
```

- **`apps`** — list of literal names the parser will recognise in finding bodies. Used to populate the `Apps:` field per finding when the upstream conversation omits it.
- **`projectRoots`** — absolute paths the skill maps the working directory against. If the cwd is `/project-root/<app>/...`, the **current scope** is `<app>`.

If the file is missing, the skill still works: every finding is treated as in-scope (since the skill cannot tell what is and isn't), and no out-of-scope warnings are emitted.

## When invoked

### 1. Read the inbox

Read `~/.claude/cowork-inbox.md`. If the file is missing or contains only the header / instruction block, respond:
> "Cowork inbox is empty. Paste the next conversation output below the `---` separator in `~/.claude/cowork-inbox.md`, then run /cowork again."

Stop.

### 2. Parse findings (lenient)

Split the inbox body (everything after the first `---` separator) using whichever rule applies first:

1. Top-level `##` markdown headings — each heading + its body is one finding.
2. `---` horizontal-rule separators (after the header separator) — each chunk is one finding.
3. Top-level numbered list items (`1.`, `2.`...) — each item is one finding.
4. If none of the above match, the whole body is treated as a single finding.

For each finding, extract:

- **Title:** first heading line, or first non-empty line, truncated to 80 chars.
- **Severity:** scan for `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `PASS` (case-insensitive). Default `—` if none found.
- **Affected apps:** if `~/.claude/cowork-config.json` lists `apps`, scan the body for each one. Otherwise mark `[unscoped]`.
- **Body:** the rest of the finding text, used as the task description when run.

### 3. Detect the current scope

If `~/.claude/cowork-config.json` is present and includes `projectRoots`:
- Match the working directory against each entry. If a match is found, the **next path segment** is the current scope.
- If no `projectRoots` matches, the scope is `<external>` and findings without explicit in-scope apps are treated as out-of-scope for safety.

If no config is present, scope is `<unconfigured>` and every finding is treated as in-scope.

### 4. Summarise the batch and ask for one confirmation

Classify each finding into one of four buckets:

- **In-scope:** `affected apps` includes the current scope, or scope is `<unconfigured>`, or the finding is `[unscoped]`.
- **Cross-repo:** `affected apps` includes the current scope **plus** at least one other.
- **Out-of-scope:** `affected apps` is entirely other apps.
- **Risk-flagged:** the finding body contains any of these markers — `DELETE`, `TRUNCATE`, `DROP`, `RESET`, `deleteMany`, `migrate reset`, `db push --force-reset`, or instructs an `UPDATE` of historical rows. These need explicit per-finding confirmation regardless of bucket.

Sort each bucket by severity (CRITICAL → HIGH → MEDIUM → LOW → PASS → —), then by inbox order. Emit a single summary block:

```
Cowork inbox — N findings (current scope: <scope>)

In-scope (will run):
  [1] [HIGH]    <title>                       apps: <list>
  [2] [MEDIUM]  <title>                       apps: <list>

Cross-repo (in-scope portion will run, follow-up note left for the rest):
  [3] [HIGH]    <title>                       apps: <list>

Out-of-scope (will skip):
  [4] [MEDIUM]  <title>                       apps: <list>

Risk-flagged (will pause for explicit confirm before each):
  [5] [HIGH]    <title>                       apps: <list>    flag: DELETE

Reply:
  'go'      — execute all in-scope + cross-repo (will pause at risk-flagged)
  'select'  — interactive cherry-pick, one at a time
  'skip'    — leave the inbox alone, exit
```

Wait for the user's reply.

### 5. Batch execution (default — on `go`)

Process findings sequentially in the order shown. For each:

1. **Project task flow.** If the project has `.claude/active-tasks.md` (cross-session coordination), read it first and check for path conflicts. Apply every rule from the project's `CLAUDE.md` — additive-migration discipline, branding, confirmation patterns, no-broken-window, whatever the project mandates. The skill does not enforce project-specific rules itself; it routes each finding through Claude Code's normal task flow so `CLAUDE.md` is honoured automatically.

2. **Run the finding** as a normal Claude Code task. The finding body is the task description.

3. **On a risk-flagged finding,** stop the batch loop and ask the user inline: *"Finding [N] '<title>' contains <flag>. Confirm to proceed (yes / skip / abort-batch)?"* Resume on yes; advance on skip; halt on abort-batch.

4. **On a cross-repo finding,** execute only the in-scope portion. Before archiving, append a follow-up note to the inbox (separate from the current finding's body):
   ```
   ## Cowork follow-up — <YYYY-MM-DD HH:MM>
   Original finding "<title>" partially handled in `<current-scope>`. Remaining apps: <list>. Run /cowork from one of those scopes to continue.
   ```

5. **On finding completion,** archive it (step 7 below) and move to the next finding without prompting.

6. **On hard failure** during a finding (typecheck regression, broken build, hook denial, schema-replay failure, project-rule violation that cannot be self-corrected): **abort the batch immediately**. Do not attempt subsequent findings. Leave the failing finding *in* the inbox (un-archived). Surface the failure in the aggregate report along with what was completed up to that point.

### 6. Cherry-pick fallback (on `select`)

If the user replies `select` instead of `go`, drop into interactive triage: ask for a finding number, run only that one through steps 5.1–5.5, archive, then prompt again for the next selection. Exit when the user says `done` or `skip`.

### 7. Archive each completed finding (atomic, mid-batch)

For each finding that completes successfully:

- Compute today's date in the user's local timezone. Use a method that does **not** silently return UTC. On Git Bash on Windows, `TZ='X' date` is unreliable — verify by checking that `date -u` differs from your method's output before relying on it.
- Slug the title: lowercase, kebab-case, drop punctuation, ≤60 chars.
- Create `~/.claude/cowork-archive/` if it does not exist.
- Move the finding text from the inbox to `~/.claude/cowork-archive/YYYY-MM-DD_<slug>.md` with this footer appended:
  ```
  ---
  Archived: <YYYY-MM-DD HH:MM>
  Outcome: <one-line summary>
  Scope(s) touched: <list>
  ```
- Remove the finding text from the inbox. Preserve the inbox header block above the first `---` separator and any remaining un-archived findings.
- Cross-repo follow-up notes left by step 5.4 stay in the inbox — they are intentionally un-archived.
- Out-of-scope findings stay in the inbox untouched — they will be picked up on a future `/cowork` run from the right scope.

### 8. Aggregate end-of-batch report

After the batch ends (either by completing every in-scope finding, by user abort, or by hard-failure halt), emit one aggregate report. If the project's `CLAUDE.md` defines a closure-report format, follow it; otherwise use this default shape:

- **Done:** count + per-finding line (title, archive filename).
- **Skipped (out-of-scope):** count + per-finding line (title, target apps).
- **Skipped (blocked by active-tasks conflict):** count + per-finding line (title, blocking id).
- **Cross-repo follow-ups left:** count + per-finding line (title, remaining apps).
- **Risk-flagged outcomes:** explicit per-finding line — confirmed / skipped / aborted.
- **Failed:** if the batch halted, the failing finding's title + what broke + the codebase state.
- **Inbox state:** how many findings remain, what they are.

End with a single sentence stating the user's next concrete action.

## Hard rules

- **One confirmation gate per batch.** Default is `go` → run all in-scope findings sequentially. Per-finding pauses happen only for risk-flagged findings (data destruction). Everything else runs without prompt.
- **Risk-flag pause is non-negotiable.** Any finding whose body mentions `DELETE`, `TRUNCATE`, `DROP`, `RESET`, `deleteMany`, `migrate reset`, `db push --force-reset`, or instructs `UPDATE` of historical rows must pause for explicit user confirmation regardless of batch mode. Auto mode does not lower this bar — data destruction needs eyes.
- **Stop on hard failure.** If a finding fails (typecheck regression, broken build, hook denial, schema-replay failure, project-rule violation that cannot be self-corrected), abort the batch. Do not run subsequent findings on top of broken state. Surface the failure with what is done so far and what is left.
- **Never wipe, truncate, reset, or rewrite the inbox** — except to remove a single completed finding when archiving it.
- **Never delete an archive file.** Findings are evidence of conversations had; they stay forever.
- **Never run an out-of-scope finding without explicit `force run`.** Cross-scope accidents are exactly the failure mode this skill exists to prevent.
- **Cross-repo orchestration is async, not synchronous.** This skill executes only the in-scope portion in the current session. Spillover is communicated via the inbox follow-up note, not by switching directories mid-session.

## Notes

- The inbox is appended to by the user (paste from upstream Claude). The skill removes findings only when archiving them on successful completion.
- If parsing fails (the upstream output is malformed or the user pasted something the splitter can't handle), tell the user what was parsed, what was not, and ask for guidance — never silently drop findings.
- This skill carries no schema, no migration, no destructive operation of its own. It is a triage and dispatch layer over Claude Code's normal task flow; every project guardrail comes from your `CLAUDE.md`.
- Cowork-side companion: the source repo ships `templates/cowork-project-instructions.md`, a custom-instructions template you paste into your upstream Claude conversation's Project settings so the upstream emits findings in inbox-ready format by default.
