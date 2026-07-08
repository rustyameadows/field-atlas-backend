# Render Deploy Prep

## Goal

Prepare the Rails backend for a free-compatible Render Blueprint deployment.

## Decisions

- Use a Git-backed Blueprint with native Ruby runtime, one web service, and one
  Render PostgreSQL database.
- Keep Solid Cache, Solid Queue, and Solid Cable in the primary database through
  normal Rails migrations.
- Mark `RAILS_MASTER_KEY` and `NPS_API_KEY` as
  Dashboard-provided secrets.

## Verification Notes

- Added `test/models/render_deploy_configuration_test.rb` to lock the single
  production DB config and primary Solid table assumptions.
- Initial focused test failed before implementation for the expected missing
  Solid tables and extra production DB configs.
- Focused deployment test passed after the migration/config changes.
- Full suite passed serially with `PARALLEL_WORKERS=1`; the default parallel
  run hit a local Ruby/pg segmentation fault while creating parallel test DBs.
- A disposable production-style database migrated successfully and contained
  `places`, `solid_cache_entries`, `solid_queue_jobs`, and
  `solid_cable_messages`.
- Production asset precompile succeeded with `SECRET_KEY_BASE_DUMMY=1`.
- The planned production start command binds to `0.0.0.0:$PORT`.
- In-app Browser verified `/` at `http://127.0.0.1:3002/`; `/up` returned 200.
- `render.yaml` parses locally, but the Render CLI is not installed here.

## Next

- Validate `render.yaml` when the Render CLI is available.
