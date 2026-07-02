# Owner Trip Sync Access

## Goal

Fix sync visibility for trips where `trips.owner_user_id` grants ownership but
the owner is missing an active `trip_members` row.

## Task List

- [x] Add regression tests for owner-only trip visibility and operation lookup.
- [x] Add regression tests for owner membership backfill events.
- [x] Make owner trips part of sync access scope.
- [x] Make trip permission helpers treat `owner_user_id` as authoritative.
- [x] Backfill missing or inactive owner `TripMember` rows and emit sync events.
- [x] Run focused and full Rails tests.

## Findings

- `Sync::AccessScope#active_trip_ids` currently only reads active
  `TripMember` rows.
- `Trip#readable_by?`, `editable_by?`, and `manageable_by?` also require an
  active member row.
- New trips created through `upsert_trip_workspace` already create an owner
  `TripMember`, so the repair is for legacy or manually-created trips.
- Incremental clients need new `sync_events` after backfill because their cursor
  may already be past the original trip creation event.

## Commands Run

- `bin/rails test test/services/sync/owner_membership_backfill_test.rb` failed
  before implementation because `Sync::OwnerMembershipBackfill` did not exist.
- `bin/rails test test/integration/field_atlas_data_api_test.rb` failed before
  implementation because owner-only trips were not readable and upsert by
  client id created a duplicate trip.
- `bin/rails test test/services/sync/owner_membership_backfill_test.rb` passed
  after implementation.
- `bin/rails test test/integration/field_atlas_data_api_test.rb` passed after
  implementation.
- `PARALLEL_WORKERS=1 bin/rails test` passed after implementation.

## Current Status

Focused tests and the full Rails suite are passing.
