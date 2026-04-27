# Configuration

The skill works without any configuration. This file documents the optional `~/.claude/cowork-config.json` you can create to enable scope-detection, so the skill knows which findings target the current repo and which target a sibling repo in the same monorepo.

## Schema

```json
{
  "apps": ["app-one", "app-two", "shared-lib"],
  "projectRoots": ["/absolute/path/to/your/project-or-monorepo"]
}
```

| Field | Type | Required | Effect |
|---|---|---|---|
| `apps` | string[] | optional | List of literal app names the parser will scan for in finding bodies. Used to populate the per-finding `Apps:` field when the upstream conversation omits it. Without this, every finding lands as `[unscoped]`. |
| `projectRoots` | string[] | optional | List of absolute paths the skill matches the working directory against. If the cwd is `<root>/<app>/...`, the next path segment becomes the **current scope**. Without this, the scope is `<unconfigured>` and every finding is treated as in-scope. |

Both fields are independently optional. The four meaningful combinations:

| `apps` | `projectRoots` | Behaviour |
|---|---|---|
| not set | not set | Every finding is in-scope. No out-of-scope warnings. Suitable for single-app users who don't want config. |
| set | not set | Findings get auto-tagged with apps they mention, but the skill cannot tell what the current scope is — every finding is treated as in-scope. |
| not set | set | The skill knows the current scope but cannot recognise app names in finding bodies — every finding is treated as in-scope. |
| set | set | Full classification: in-scope vs cross-repo vs out-of-scope vs risk-flagged. Recommended for monorepos. |

## Examples

### Single-app project (no config needed)

Most projects don't need a config file. The skill defaults to "everything in-scope" which works fine when you only ever dispatch findings for one repo.

### Multi-app monorepo

```json
{
  "apps": ["web", "api", "worker", "shared"],
  "projectRoots": ["/Users/you/code/acme-monorepo"]
}
```

When you `cd /Users/you/code/acme-monorepo/web && claude` and run `/cowork`, the current scope is `web`. Findings tagged `Apps: web` run; findings tagged `Apps: api` are skipped (the skill tells you to re-run from `api/`); findings tagged `Apps: web, api` run only the in-scope portion and leave a follow-up note in the inbox.

### Multiple monorepos on one machine

```json
{
  "apps": [
    "web", "api", "worker",
    "marketing-site", "admin-panel",
    "ledger", "docs", "auth"
  ],
  "projectRoots": [
    "/Users/you/code/acme-monorepo",
    "/Users/you/code/personal-stuff",
    "/Users/you/code/atlas-labs"
  ]
}
```

The skill matches the cwd against each root in turn. Apps from any monorepo are recognised in finding bodies, since the inbox is global and a single dispatch may reference apps from multiple monorepos.

## Where the file lives

`~/.claude/cowork-config.json` (Windows: `C:\Users\<you>\.claude\cowork-config.json`).

## What the skill never reads

- `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, or any other monorepo manifest. The skill does not auto-discover apps. The list in `cowork-config.json` is authoritative.
- `.git`, `.cursor`, or any other tool's config files.

If you want the skill to recognise a new app, add it to `apps`. There is no auto-detection on purpose — the trade-off is one config edit per new app, in exchange for never having to debug surprising scope-detection behaviour.

## Validation

The skill does not validate the JSON beyond parsing it. Malformed JSON (missing comma, trailing comma, bad quoting) makes the skill fall back to the no-config behaviour silently — verify your file with a JSON linter or by running `/cowork` and checking the summary block's `current scope:` line.
