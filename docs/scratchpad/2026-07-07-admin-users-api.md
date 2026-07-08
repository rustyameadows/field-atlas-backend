# Admin Users API

## Goal

Expose `GET /api/v1/admin/users?limit=250` for the iOS admin users table.

## Decisions

- Endpoint is admin-only and reuses bearer API session auth.
- Response is `{ "users": [...] }` with no pagination metadata.
- `map_count` is the public wire name for active `PlaceList` ownership.
- `last_seen_at` is always present and comes from the latest active device
  `last_seen_at`, or `null`.

## Verification

- Added integration tests for admin success, 403, 401, nullable last seen,
  profile photo shape, counts, and limit cap.
- Initial tests failed with 404 before route/controller implementation.
- `bin/rails test test/integration/admin_users_api_test.rb` passed.
- `bin/rails test test/integration/field_atlas_data_api_test.rb test/integration/admin_users_api_test.rb` passed.
- Default parallel `bin/rails test` hit the known local native `pg` crash; serial
  `PARALLEL_WORKERS=1 bin/rails test` passed.
