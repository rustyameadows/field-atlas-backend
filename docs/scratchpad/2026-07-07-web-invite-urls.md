# Web Invite URLs

## Goal

Replace backend invite URL generation with public web URLs:
`https://field-atlas.com/invites/?token=<token>`.

## Decisions

- Keep invite API endpoints unchanged.
- Remove the retired invite-host env var; use `FIELD_ATLAS_WEB_BASE_URL` for
  invite links and declare `FIELD_ATLAS_API_BASE_URL` separately.
- Centralize URL construction in `TripInviteUrl`.
- Backfill existing `trip_invites.url` values with the new public URL format.

## Verification

- Added red tests for invite URL building, direct invite creation, sync-created
  invites, sync serialization, and Render env config.
- Initial focused tests failed on the old local `/invites/:token` URLs and
  missing new env vars.
- Focused API/config/contract tests passed.
- Full suite passed with `PARALLEL_WORKERS=1 bin/rails test`.
