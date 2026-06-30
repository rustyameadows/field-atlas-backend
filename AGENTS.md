# AGENTS.md

## Repository Mission

Field Atlas Backend is a Rails API and local admin surface for canonical places,
provider source records, provider-backed search, and external identifier
associations used by the Field Atlas iOS app.

Canonical `Place` records are the app identity. Provider records and external
identifiers enrich or link to canonical places; they do not replace canonical
identity.

## Current State

- Rails 8.1 app with PostgreSQL/PostGIS.
- API namespace lives under `/api/v1`.
- Search is provider-aware through Field Atlas canonical places and NPS source
  records.
- External provider IDs, including MapKit IDs, are stored as verified
  crosswalks on canonical places.
- The local dashboard is available at `/`.

## Durable Context

Read these before non-trivial work:

- `README.md` for setup, API examples, and local run commands.
- `docs/CODEX_WORKFLOW.md` for Codex workflow, browser verification, task
  lists, and scratchpad expectations.

## Working Agreements

- Start with repo context: inspect relevant files and check
  `git status --short --branch`.
- Preserve user changes. Never revert unrelated edits unless explicitly asked.
- Keep changes tightly scoped to the request.
- Prefer `rg` and `rg --files` for search.
- Use Rails conventions and structured APIs over ad hoc parsing.
- Use `apply_patch` for manual file edits.
- Keep an active task list for any non-trivial or multi-step task. Skip it only
  for small, direct code or docs changes.
- For bigger tasks, keep a scratchpad with findings, decisions, current status,
  and next steps so context survives compaction or handoff.

## Browser And Verification

- Use only the Codex in-app Browser for local browser verification.
- Before browser verification, review the Browser skill/instructions available
  in the current Codex session.
- Do not use macOS `open`, external browsers, or screenshots as a substitute
  when the in-app Browser can inspect the local app.
- When app behavior is user-visible, start or reuse the local server and provide
  the running URL used for verification.

## Rails Commands

Setup:

```sh
bundle install
PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH bin/rails db:prepare
```

Run locally:

```sh
bin/rails server -b 127.0.0.1 -p 3000
```

Verify:

```sh
bin/rails test
```

If running inside Codex sandbox, database commands may need elevated execution
because local PostgreSQL runs as a host service.

## Definition Of Done

For docs-only tasks, docs are accurate, linked, and not duplicative.

For code tasks, behavior matches the request, relevant tests/checks have run,
and the final response includes changed files, verification performed, and any
running local server URL needed for review.
