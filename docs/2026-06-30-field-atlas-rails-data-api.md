# Field Atlas Rails Data API Plan

## Purpose

Provide the Rails API required by the new Field Atlas iOS data layer.

Rails is the canonical backend for synced Field Atlas user data. The immediate
delivery must cover authentication, device registration, synced trip planning,
route snapshots, collaboration, invite links, operation push, cursor pull, and
the additional user-data records already present in the iOS SQLite foundation.

This is not a places/search rewrite. The existing canonical `Place` and provider
source work remains separate. Trip stops may reference canonical places, but
place search database work should not block the user/trip sync API.

This document is written for the backend developer implementing the API that
the iOS `TripRepository`, `SyncEngine`, and account/device sync code consume.

## Current Backend Baseline

The Rails app currently has:

- Rails 8.1, PostgreSQL, and PostGIS.
- `/api/v1` JSON controllers for place search, place options, canonical place
  creation, and place external identifiers.
- No user auth, device registration, API sessions, sync cursors, trips, members,
  invites, or operation processing yet.
- Normal bigint primary keys on existing place/search tables.

The new synced user-data subsystem should be added alongside the current places
API. Do not refactor existing place search as part of this work unless a trip
sync feature directly requires a small integration point.

## Consuming Client Context

The iOS app currently uses:

- SwiftUI and MapKit.
- GRDB / SQLite for the new local data layer.
- `TripRepository` as the app-facing trip persistence API.
- `SyncEngine` for operation push and cursor pull.
- `FieldAtlasRailsAPIClient` for auth, device, and sync request construction.
- Local-first editing: user edits write to SQLite first, then enqueue pending
  operations for Rails.

Rails must not be in the direct path of every user tap.

Relevant current client request paths:

```text
POST   /api/v1/auth/apple
POST   /api/v1/auth/refresh
DELETE /api/v1/auth/session
GET    /api/v1/me
POST   /api/v1/devices
PATCH  /api/v1/devices/:id
GET    /api/v1/sync?cursor=...
POST   /api/v1/sync/operations
```

The current client already sends snake_case JSON request keys. Response fixtures
should also use snake_case.

## Delivery Requirement

This can be implemented internally in phases, but it must be delivered as one
complete backend capability for the client data-layer branch.

Do not leave out records the client is preparing to store or send. The first
backend delivery must support:

- Accounts and Sign in with Apple.
- API sessions and refresh tokens.
- Devices.
- Trips.
- Trip members.
- Trip invites.
- Trip segments.
- Trip stops.
- Trip stop option links.
- Route snapshots, snapshot stops, route legs, and route steps.
- Favorite places.
- Place lists and place list items.
- Search history entries.
- Search sessions.
- Search result snapshots.
- User settings.
- Memory assets.
- Drive sessions.
- Client operations.
- Sync events.
- Deleted record markers.
- Contract JSON fixtures for the iOS app.

It is acceptable for some non-trip data types to start as structured pass-through
sync records with JSONB payload columns, but they must have server IDs,
revisions, tombstones, authorization, and sync events from day one.

## iOS Schema Parity Requirements

The latest iOS data-shape source is `DestinationApp/Core/FieldAtlasDatabase.swift`.
Treat the local SQLite schema as the minimum backend contract. Rails may add
server-only columns, stronger ownership columns, and normalized JSONB payloads,
but it must not omit or rename data the client is already storing.

Current local compatibility columns that must be accounted for:

- `trips.encoded_workspace`
- `trip_segments.encoded_segment`
- `trip_stops.encoded_item`
- `trip_stops.encoded_placement`
- `route_snapshots.routing_signature`
- `route_snapshots.encoded_route`
- `route_legs.encoded_polyline`
- `route_steps.encoded_polyline`
- `favorite_places.encoded_place`
- `place_list_items.encoded_place`
- `search_history_entries.encoded_entry`
- `search_sessions.encoded_session`
- `search_result_snapshots.encoded_place`
- `memory_assets.encoded_asset`
- `drive_sessions.encoded_session`

Rails should store these as JSONB whenever the client sends decoded JSON. If the
client sends binary `Data` or a base64 string, Rails should preserve it in a
payload field without lossy parsing. The implementation can later split fields
out of these payloads as product needs harden.

Current local table identity pattern:

- Most user data tables have local `id` and optional `server_id`.
- `user_settings` uses `key` as the local primary identity and has no local
  `server_id` today.
- Route child tables currently have local `id` but no local `server_id`,
  `deleted_at`, or `revision` columns.
- Sync metadata tables (`pending_operations`, `sync_cursors`, `sync_errors`,
  `deleted_records`) are client-side bookkeeping and are not themselves pulled
  as ordinary user records.

Backend implication:

- Return `server_id` mappings where the current local schema can store them.
- For `user_settings`, map by `key` and return any server UUID in the sync
  record envelope rather than requiring the current client to persist
  `server_id`.
- For route child rows, use stable IDs supplied by the client where possible,
  include them inside route snapshot payloads, and add standalone child record
  envelopes only once the client enum/storage is aligned.
- Keep `sync_status` as a client-local state. Rails should not serialize it as a
  canonical server attribute unless a later client contract asks for it.

## GRDB And Rails Boundary Gotchas

This API crosses a local SQLite/GRDB store and a Rails/PostgreSQL service. The
implementation should explicitly handle the boundary instead of assuming the two
layers serialize values the same way.

### Date And Time Encoding

Rails API responses should use ISO 8601 timestamps with UTC offsets. The client
SQLite store may persist dates in GRDB's database format, but API fixtures must
exercise the network format the Swift client decodes.

Rules:

- Serialize API timestamps as ISO 8601 UTC strings.
- Accept ISO 8601 strings from the client.
- Normalize server persistence to UTC.
- Include date round-trip fixture tests for auth, device, trips, route
  snapshots, invites, memory assets, and drive sessions.
- Treat date-only fields such as `start_date` and `end_date` as calendar dates,
  not instants, unless the client contract explicitly sends a timestamp.

### UUIDs And Local Text IDs

The current iOS schema stores IDs as text. Rails should expose UUIDs as lowercase
strings and should not require the client to decode UUID-specific binary values.

Rules:

- Use UUIDs for Rails syncable server IDs.
- Serialize UUIDs as strings.
- Accept client local IDs as arbitrary strings.
- Keep local ID to server UUID mapping in operation responses.
- Do not assume client local IDs are UUIDs. Existing local IDs may be stable
  slugs, composite strings, or generated UUID strings.

### Binary And Encoded Payloads

GRDB stores Swift `Data` as SQLite blobs, while the Rails API receives JSON.
The current iOS client may send a decoded JSON object when the payload is JSON,
or a base64 string when the payload cannot be decoded as JSON.

Rules:

- Accept `operations[].payload` as either a JSON object, JSON array, scalar, or
  base64 string.
- Preserve unrecognized encoded payloads without lossy parsing.
- Store parsed payloads in JSONB when possible.
- Store base64 payloads with an explicit marker such as
  `{ "encoding": "base64", "data": "..." }` if the server cannot parse them.
- Do not reject an otherwise valid operation only because its nested encoded
  Swift payload is not normalized yet.

### GRDB Queue And Transaction Expectations

The iOS app writes local data and pending operations in one SQLite transaction
through GRDB. Rails should mirror that atomicity on the server.

Rules:

- Process each pushed operation in a database transaction.
- Within that transaction, mutate records, increment revisions, create
  tombstones, append sync events, and persist the client operation result.
- Do not create sync events outside the transaction that changes the record.
- Do not send APNs or websocket hints until after the database transaction
  commits.
- Keep pull pages repeatable because the client only advances its cursor after
  a successful local transaction.

### Rails Strong Parameters And Dynamic Payloads

Operation wrappers are structured, but nested `payload` contents vary by action
and may include future client fields.

Rules:

- Strongly validate the operation wrapper: `operation_id`, `device_id`,
  `entity_type`, `entity_id`, `action`, `base_revision`, `created_at`,
  `payload`.
- Do not mass-assign arbitrary payload hashes into Active Record models.
- Route each operation through an action-specific payload adapter.
- Preserve unknown fields in `client_payload` where appropriate.
- Avoid broad strong-params patterns that accidentally allow arbitrary future
  model attributes into server-owned columns.

### Rails Transaction Failure Handling

Rails database errors can poison the current transaction. Operation processing
should avoid rescuing low-level database statement errors inside a transaction
and then continuing as if the transaction were usable.

Rules:

- Validate as much as possible before entering the mutation transaction.
- Use model/service validation errors for normal per-operation `rejected`
  results.
- Let unexpected database statement errors roll back the operation transaction.
- Record the operation as failed only in a fresh transaction after rollback, if
  the failure should be persisted.
- Prefer unique constraints for idempotency and handle duplicate operation keys
  by loading the existing operation result.

Primary references checked for this section:

- GRDB README sections on database connections and Data/Date/UUID coding.
- Rails Active Record transaction documentation.
- Rails transaction callback documentation.
- Rails Action Controller strong parameters documentation.

## Design Principles

- Rails is canonical for synced data.
- iOS remains usable offline.
- Sync is operation-based for local edits and cursor-based for canonical pulls.
- Every syncable record has a stable public UUID server ID and a revision.
- New sync tables use UUID public primary keys or UUID public IDs.
- Deletes are represented as tombstones/deleted markers, not silent
  disappearances.
- Private and shared trips use the same trip storage model.
- Access is controlled through membership records.
- Removed members lose access on the next sync request.
- Route snapshots are generated client artifacts, separate from editable trip
  data.
- Realtime delivery may hint that the client should sync, but correctness comes
  only from the sync API.
- The API should match the richer Field Atlas planning environment, not a simple
  stop list.

## Public API Conventions

### JSON

Use JSON request and response bodies with snake_case keys.

Use ISO 8601 strings for timestamps. Use `null` for absent optional values.

Operation wrapper keys are snake_case, but `operations[].payload` may contain
the raw encoded Swift model shape. That nested payload may use camelCase keys
such as `startDate`, `primarySegmentID`, or `createdAt`. Rails should preserve
the payload and parse known fields through operation-specific adapters rather
than rejecting the operation only because nested payload keys are not snake_case.

Return validation errors in a stable shape:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed",
    "details": [
      {
        "field": "title",
        "message": "can't be blank"
      }
    ]
  }
}
```

Operation-level failures use per-operation `rejected` or `conflict` results
rather than failing the entire batch unless the request itself is malformed.

### Authentication Header

Authenticated requests use:

```text
Authorization: Bearer <access_token>
```

Do not accept user IDs from the request body as the source of truth. The current
user comes from the API session.

### Public IDs

Use UUID strings for all new server-owned synced records. The API should expose
UUIDs, not Rails integer IDs.

Implementation preference:

- Enable `pgcrypto` in a migration.
- Use `id: :uuid, default: -> { "gen_random_uuid()" }` for new sync tables.
- Keep existing place/search tables unchanged.
- If an internal bigint ID is ever needed for performance, add a separate
  private column and keep the public API UUID stable.

Client records may begin life with local IDs that are not UUIDs. The sync API
must support mapping local IDs to server UUIDs through operation results and
pull records.

### Local ID Mapping

Create operations include `entity_id`, which is the client's local entity ID.
For accepted create operations, Rails returns:

- `entity_id`: the client-provided local ID from the operation.
- `server_id`: the Rails UUID for the canonical record.
- `revision`: the accepted server revision.

For update/delete operations against records already known to Rails, the client
may send either a server UUID as `entity_id` or a local ID plus enough payload
context for Rails to resolve it. Prefer server UUIDs after the first accepted
sync.

For aggregate operations such as `upsert_trip_workspace`, return a `mappings`
array for every nested record created or matched.

```json
{
  "operation_id": "op-123",
  "status": "accepted",
  "entity_type": "trip",
  "entity_id": "local-trip-1",
  "server_id": "2b73d044-8a26-44a7-a42f-64e3f5e9f30d",
  "revision": 4,
  "mappings": [
    {
      "entity_type": "trip_stop",
      "entity_id": "local-stop-1",
      "server_id": "5b3230e5-40d7-4b2c-9bb1-91c1b7481664",
      "revision": 1
    }
  ]
}
```

## Record Envelope

Pull sync should return canonical records in a common envelope:

```json
{
  "type": "trip_stop",
  "id": "5b3230e5-40d7-4b2c-9bb1-91c1b7481664",
  "revision": 7,
  "updated_at": "2026-06-30T22:10:00Z",
  "deleted_at": null,
  "attributes": {
    "trip_id": "2b73d044-8a26-44a7-a42f-64e3f5e9f30d",
    "kind": "route_stop",
    "title": "Lost Mine Trail",
    "sort_key": 2000.0
  }
}
```

Use the same envelope for all syncable record types. Child route records may be
nested in a route snapshot response for convenience, but each child still needs
stable IDs and deterministic serialization.

## Important Data Shape Decision

Use one canonical `trip_stops` resource for ideas, route stops, possible stops,
route waypoints, and notes.

Do not create separate primary backend resources such as
`trip_route_waypoints` or `trip_possible_stops`.

Field Atlas frequently changes one planning item into another:

- idea to route stop
- possible stop to route stop
- route waypoint to possible stop
- option candidate to route stop
- route stop back to possible stop

Those transitions should update one `trip_stops.kind` value instead of moving
data between tables or resources.

The current iOS code uses these raw stop-kind values:

- `idea`
- `route_stop`
- `possible_stop`
- `waypoint`
- `note`

Rails should support those values as canonical API values. If older docs or
payloads send `open_idea` or `route_waypoint`, normalize them at the API
boundary:

- `open_idea` -> `idea`
- `route_waypoint` -> `waypoint`

Only `route_stop` and `waypoint` affect route calculation on iOS.

## Backend Responsibilities

Rails owns:

- User accounts.
- Sign in with Apple session exchange.
- Future non-Apple auth identities on the same `users` table.
- API sessions and refresh tokens.
- Device registration.
- Synced trip records.
- Server UUIDs.
- Record revisions.
- Sync cursors.
- Deleted record markers.
- Sync event generation.
- Client operation idempotency.
- Client operation acceptance/rejection/conflict results.
- Invite links.
- Shared trip access.
- API validation.
- Push or realtime sync hints.

Rails does not own:

- Native SwiftUI screens.
- Local-first edit behavior.
- MapKit route calculation.
- MapKit search UI.
- Client route rendering.
- Client-only temporary drafts that have not been enqueued for sync.

## Auth Model

Use Sign in with Apple for the primary iOS account creation path.

Also create a first-party `users` table that is not Apple-specific. Apple auth
should attach an identity to a user, not replace the app user model. This keeps
space for direct login or other identity providers later.

### Tables

`users`:

- `id` UUID primary key
- `display_name`
- `email`
- `email_verified` boolean
- `time_zone`
- `status` (`active`, `disabled`, `deleted`)
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

`user_auth_identities`:

- `id` UUID primary key
- `user_id`
- `provider` (`apple`, future `email`, future provider names)
- `provider_subject`
- `email`
- `email_verified` boolean
- `display_name`
- `raw_claims` JSONB
- `last_verified_at`
- `created_at`
- `updated_at`

Unique indexes:

- `[provider, provider_subject]`
- Lowercase email if/when direct email auth is added.

`api_sessions`:

- `id` UUID primary key
- `user_id`
- `device_id`
- `access_token_digest`
- `refresh_token_digest`
- `expires_at`
- `refresh_expires_at`
- `last_used_at`
- `revoked_at`
- `created_at`
- `updated_at`

Never store raw access or refresh tokens. Store digests.

### Apple Auth Endpoint

```text
POST /api/v1/auth/apple
```

Current client request body:

```json
{
  "identity_token": "apple-jwt",
  "authorization_code": "optional-code",
  "nonce": "raw-nonce-sent-to-rails",
  "full_name": "Avery Field",
  "email": "avery@example.com",
  "device_name": "Avery's iPhone"
}
```

Backend behavior:

1. Verify Apple's identity token.
2. Validate issuer, audience, expiration, issued-at, and subject.
3. If the client supplies `nonce`, SHA-256 hash the raw nonce and compare it to
   the identity token's `nonce` claim.
4. Find or create `user_auth_identities(provider: "apple", provider_subject:
   sub)`.
5. Find or create the associated `user`.
6. Update display name and email conservatively. Apple may only send name/email
   on first authorization.
7. Create an API session.
8. Optionally create or return a device if device metadata is supplied.

Apple verifier implementation:

- Add an `AppleIdentityVerifier` service.
- Fetch and cache Apple's JWK set.
- Verify token signature and claims.
- In tests, inject a fake verifier with deterministic claims.
- Do not couple controllers directly to JWT/JWK details.

Suggested response:

```json
{
  "user": {
    "id": "0cebb1af-4810-42bc-a92b-06e8c670d2a5",
    "display_name": "Avery Field",
    "email": "avery@example.com",
    "revision": 1,
    "created_at": "2026-06-30T22:00:00Z",
    "updated_at": "2026-06-30T22:00:00Z"
  },
  "session": {
    "id": "1c58424d-4ff6-43bb-881d-1d449077fb21",
    "access_token": "raw-access-token",
    "refresh_token": "raw-refresh-token",
    "expires_at": "2026-06-30T23:00:00Z",
    "refresh_expires_at": "2026-07-30T22:00:00Z"
  },
  "device": null
}
```

### Refresh Endpoint

```text
POST /api/v1/auth/refresh
```

Request:

```json
{
  "refresh_token": "raw-refresh-token"
}
```

Behavior:

- Validate refresh token digest.
- Reject revoked or expired sessions.
- Rotate access token.
- Prefer rotating refresh token too.
- Update `last_used_at`.
- Return the same response session shape as Apple auth.

### Logout Endpoint

```text
DELETE /api/v1/auth/session
```

Behavior:

- Requires bearer access token.
- Marks the current session `revoked_at`.
- Does not delete user data, devices, trips, pending operations, or sync events.

### Me Endpoint

```text
GET /api/v1/me
```

Behavior:

- Requires bearer access token.
- Returns the authenticated user plus current session and current device if the
  session is associated with one.

## Device API

Devices are first-class sync participants. They are used for operation
attribution, route snapshot attribution, push hints, and debugging.

### Tables

`devices`:

- `id` UUID primary key
- `user_id`
- `client_device_id`
- `name`
- `platform`
- `app_version`
- `build_number`
- `push_token`
- `push_environment` (`development`, `production`, nullable)
- `last_seen_at`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

Unique index:

- `[user_id, client_device_id]`

The current iOS client sends `device_id` for the local device identifier. Store
that as `client_device_id`, not as the Rails UUID.

### Register Device

```text
POST /api/v1/devices
```

Current client request body:

```json
{
  "device_id": "local-device-uuid",
  "name": "Avery's iPhone",
  "platform": "ios",
  "app_version": "1.0"
}
```

Also accept:

- `build_number`
- `push_token`
- `push_environment`

Behavior:

- Requires bearer access token.
- Upserts by `[current_user.id, device_id]`.
- Updates metadata and `last_seen_at`.
- Returns the Rails device UUID as `id` and echoes `client_device_id`.

### Update Device

```text
PATCH /api/v1/devices/:id
```

Current client request body:

```json
{
  "name": "Avery's iPhone",
  "push_token": "apns-token"
}
```

Behavior:

- Requires bearer access token.
- Device must belong to current user.
- Updates provided metadata only.

## Required Syncable Resources

The first backend delivery must support these entity types:

```text
user
device
trip
trip_member
trip_invite
trip_segment
trip_stop
trip_stop_option_link
route_snapshot
route_snapshot_stop
route_leg
route_step
favorite_place
place_list
place_list_item
search_history_entry
search_session
search_result_snapshot
user_setting
memory_asset
drive_session
```

The current iOS enum is missing explicit values for `place_list_item`,
`search_result_snapshot`, `route_snapshot_stop`, `route_leg`, and `route_step`.
Rails should still implement these record types in the sync envelope and
contract fixtures. The client should align its enum before live sync.

Until the client enum/storage is aligned, route child rows and search result
snapshots may be delivered nested inside their parent records:

- `route_snapshot_stop`, `route_leg`, and `route_step` inside
  `route_snapshot.attributes`.
- `search_result_snapshot` inside `search_session.attributes` or as a separate
  envelope once the client can apply it.

The backend should still model and test them as first-class server records so
they have deterministic IDs, tombstones, and fixture coverage.

## Common Sync Columns

Each syncable table should have:

- `id` UUID primary key
- `created_at`
- `updated_at`
- `deleted_at`
- `revision` integer, null false, default 1
- `created_by_user_id` where attribution matters
- `created_by_device_id` where attribution matters
- Optional `client_payload` JSONB for fields not yet normalized

Revision rules:

- Revision starts at 1 for a server-created record.
- Every accepted server mutation increments that record's revision.
- Soft delete increments revision and sets `deleted_at`.
- Child replacement during aggregate operations increments changed child
  records and tombstones removed child records.

Do not use Rails `lock_version` as the public sync revision. Use explicit
`revision` fields and central mutation services.

## Trip Records

`trips` are server-backed workspaces with stable identity.

Fields:

- `id` UUID primary key
- `owner_user_id`
- `title`
- `start_date`
- `end_date`
- `created_by_device_id`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `sync_status` client-local only; do not treat as canonical server state
- `encoded_workspace`
- `client_payload` JSONB

Rules:

- Creating a trip also creates an owner `trip_member`.
- Private trips are trips whose only active member is the owner.
- Shared trips use the same table and same sync operations.
- Owners can rename, date-edit, delete, invite, remove members, and change
  member roles.
- Editors can edit planning records but cannot remove owners or manage owner
  role.
- Viewers can read but not mutate planning records.
- Preserve the current client `encoded_workspace` payload when
  `upsert_trip_workspace` sends it. Rails should normalize known fields and keep
  the encoded compatibility payload available for round-trip fixture checks.

## Trip Membership

`trip_members` controls read/write access.

Fields:

- `id` UUID primary key
- `trip_id`
- `user_id`
- `display_name`
- `role`
- `status`
- `joined_at`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

Roles:

- `owner`
- `editor`
- `viewer`

Statuses:

- `active`
- `removed`

The current iOS local table stores `deleted_at` but does not yet have a
membership `status` column. Rails should serialize both `status` and
`deleted_at` in contract fixtures. Until the client adds a `status` column, it
can derive active versus removed from `deleted_at`.

Rules:

- There must always be at least one active owner for a non-deleted trip.
- Removed members cannot read or mutate the trip through sync.
- Removing a member should create sync tombstones or access-revoked markers for
  that user on their next pull.
- A removed member's future push operations for that trip are rejected.

## Trip Invites

Invite links allow shared planning to start from a native iOS share sheet or
Universal Link.

Endpoints:

```text
POST   /api/v1/trips/:trip_id/invites
GET    /api/v1/invites/:token
POST   /api/v1/invites/:token/accept
DELETE /api/v1/trips/:trip_id/members/:member_id
PATCH  /api/v1/trips/:trip_id/members/:member_id
```

`trip_invites` fields:

- `id` UUID primary key
- `trip_id`
- `token`
- `url`
- `invited_by_user_id`
- `accepted_by_user_id`
- `role`
- `status`
- `expires_at`
- `accepted_at`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

Statuses:

- `pending`
- `accepted`
- `revoked`
- `expired`

The current iOS local table stores invite `token`, `url`, `status`,
timestamps, and expiration, but does not yet store inviter, accepter, role, or
accepted timestamp. Rails should own those richer fields and include them in
fixtures so the client can add columns without changing endpoint semantics.

Create invite request:

```json
{
  "role": "editor",
  "expires_in_seconds": 604800
}
```

Response:

```json
{
  "invite": {
    "id": "1f5a9f28-a2df-4899-93ec-b2e29feabf56",
    "trip_id": "2b73d044-8a26-44a7-a42f-64e3f5e9f30d",
    "token": "invite-token",
    "url": "https://field-atlas.com/invites/?token=invite-token",
    "role": "editor",
    "status": "pending",
    "expires_at": "2026-07-07T22:00:00Z"
  }
}
```

`GET /api/v1/invites/:token` may be unauthenticated and should return only a
safe preview: trip title, inviter display name, role, and expiration. Accepting
an invite requires authentication.

## Trip Segments

Segments represent trip days or manually organized route sections.

Fields:

- `id` UUID primary key
- `trip_id`
- `title`
- `container_type`
- `segment_kind`
- `auto_day_index`
- `parent_segment_id`
- `start_date`
- `end_date`
- `sort_key`
- `color_token_id`
- `encoded_segment`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

Current iOS concepts to preserve:

- `container_type`: `day`, `segment`, `leg`, `collection`, `phase`
- `segment_kind`: `manual`, `tripDefault`, `autoDay`
- `color_token_id`: stable client visual token
- `sort_key`: numeric ordering value

The backend does not calculate routes or generate day segments. It stores and
syncs the client-created organization.

## Trip Stops

`trip_stops` is the main planning item table.

Fields:

- `id` UUID primary key
- `trip_id`
- `segment_id`
- `item_id`
- `placement_id`
- `kind`
- `title`
- `subtitle`
- `notes`
- `sort_key`
- `place_title`
- `place_subtitle`
- `address`
- `latitude`
- `longitude`
- `source`
- `source_identifier`
- `provider`
- `provider_id`
- `canonical_place_id`
- `source_ids` JSONB
- `location_target` JSONB
- `encoded_item`
- `encoded_placement`
- `created_by_user_id`
- `created_by_device_id`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

Canonical `kind` values:

- `idea`
- `route_stop`
- `possible_stop`
- `waypoint`
- `note`

Accepted aliases at API boundary:

- `open_idea`
- `route_waypoint`

Rules:

- Changing a stop's planning role updates `kind` on the same row.
- `sort_key` controls ordering within a trip or segment.
- `segment_id` may be null for unplaced ideas.
- `canonical_place_id` references the existing `places` table when the stop is
  linked to a Field Atlas canonical place.
- Provider snapshot fields should remain even when `canonical_place_id` is
  present, because the client may need the original MapKit/NPS snapshot offline.
- `source_ids` can store provider ID crosswalks copied from search results.
- Preserve current client `encoded_item` and `encoded_placement` payloads for
  compatibility while normalized stop fields settle.
- Location may be exact, regional, coordinate-only, route-corridor, near another
  item, text-only, or unknown. Normalize exact coordinates into latitude and
  longitude, and preserve richer shape in `location_target`.

## Option Links

Option groups use association records. They are not a separate resource tree.

An idea such as "Choose Big Bend first hike" is a `trip_stops` row with kind
`idea`. Candidate options such as "Lost Mine Trail" and "Window Trail" are also
`trip_stops` rows. The association lives in `trip_stop_option_links`.

Fields:

- `id` UUID primary key
- `trip_id`
- `group_id`
- `parent_stop_id`
- `candidate_stop_id`
- `group_title`
- `role`
- `status`
- `is_selected`
- `sort_key`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

Rules:

- The parent and candidate stops must belong to the same trip.
- A candidate can become a route stop by updating its own `kind` and segment
  assignment.
- Selecting an option updates the link row, not the stop row.
- The API may accept `idea_stop_id`/`option_stop_id` aliases, but should
  serialize `parent_stop_id`/`candidate_stop_id` to match current iOS storage.

## Route Snapshots

Route calculation remains local to iOS through Apple frameworks. Rails stores
route output generated by the client.

`route_snapshots` fields:

- `id` UUID primary key
- `trip_id`
- `segment_id`
- `created_by_user_id`
- `created_by_device_id`
- `provider`
- `stale`
- `total_distance_meters`
- `expected_travel_time`
- `routing_signature` JSONB
- `encoded_route`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

`route_snapshot_stops` fields:

- `id` UUID primary key
- `snapshot_id`
- `stop_id`
- `kind`
- `sort_key`
- `latitude`
- `longitude`
- `title`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

`route_legs` fields:

- `id` UUID primary key
- `snapshot_id`
- `source_stop_id`
- `destination_stop_id`
- `name`
- `label`
- `distance_meters`
- `expected_travel_time`
- `encoded_polyline`
- `sort_key`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

`route_steps` fields:

- `id` UUID primary key
- `leg_id`
- `instructions`
- `notice`
- `distance_meters`
- `transport_type`
- `encoded_polyline`
- `sort_key`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

Rules:

- Saving a route snapshot may replace its child snapshot stops, legs, and steps
  in one transaction.
- Use `snapshot_id`, `stop_id`, `kind`, and `leg_id` in serialized attributes to
  match the current iOS schema. The Rails model may use clearer association
  names internally, but serializers must honor client field names.
- Route-affecting trip edits should mark relevant snapshots stale.
- If a route snapshot is saved against an already-stale route signature, accept
  it but set `stale: true` unless the operation is malformed.
- Pull sync may nest child stops, legs, and steps inside the route snapshot
  record, but child records still need stable IDs for tombstones and fixtures.

## Additional User Data Resources

The iOS SQLite layer already contains user map/search/memory/drive records. The
backend must support them in the first sync delivery. These can start with
structured key columns plus `client_payload` JSONB so the server does not lose
client details while the product model settles.

### Favorite Places

`favorite_places` fields:

- `id` UUID primary key
- `user_id`
- `place_id`
- `name`
- `favorited_at`
- `encoded_place`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

`place_id` may refer to a canonical Field Atlas place ID or a client/provider
place identity. Preserve the full client place snapshot from `encoded_place` in
`client_payload` or a decoded JSONB equivalent.

### Place Lists

`place_lists` fields:

- `id` UUID primary key
- `user_id`
- `name`
- `marker_shape`
- `marker_color_red`
- `marker_color_green`
- `marker_color_blue`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

`place_list_items` fields:

- `id` UUID primary key
- `place_list_id`
- `place_id`
- `sort_key`
- `encoded_place`
- `added_at`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

### Search History And Sessions

`search_history_entries` fields:

- `id` UUID primary key
- `user_id`
- `query`
- `searched_at`
- `latitude`
- `longitude`
- `encoded_entry`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

`search_sessions` fields:

- `id` UUID primary key
- `user_id`
- `history_entry_id`
- `query`
- `encoded_session`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

`search_result_snapshots` fields:

- `id` UUID primary key
- `owner_type`
- `owner_id`
- `place_id`
- `sort_key`
- `encoded_place`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `client_payload` JSONB

### User Settings

`user_settings` fields:

- `id` UUID primary key
- `user_id`
- `key`
- `value`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`

Unique index:

- `[user_id, key]`

The current iOS table uses `key` as its primary key and has no `id` or
`server_id`. Rails should still use a UUID internally, but sync operations and
fixtures must allow the client to address settings by `key`.

### Memory Assets

`memory_assets` fields:

- `id` UUID primary key
- `user_id`
- `trip_id`
- `drive_session_id`
- `kind`
- `title`
- `local_file_name`
- `transcript`
- `transcript_status`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `encoded_asset`
- `client_payload` JSONB

This first API pass does not need to upload binary media unless the client is
already sending it. It must sync metadata and leave room for Active Storage
attachments later.

### Drive Sessions

`drive_sessions` fields:

- `id` UUID primary key
- `user_id`
- `trip_id`
- `route_snapshot_id`
- `started_at`
- `ended_at`
- `created_at`
- `updated_at`
- `deleted_at`
- `revision`
- `encoded_session`
- `client_payload` JSONB

## Sync Events

`sync_events` is the backbone of cursor pull.

Use an append-only event table. Every accepted mutation that changes a syncable
record creates a sync event in the same database transaction.

Fields:

- `id` bigint primary key, monotonically increasing
- `event_uuid` UUID
- `entity_type`
- `entity_id`
- `trip_id`
- `user_id`
- `actor_user_id`
- `actor_device_id`
- `action` (`created`, `updated`, `deleted`, `access_revoked`)
- `record_revision`
- `occurred_at`
- `metadata` JSONB

Notes:

- `id` is the internal cursor sequence.
- `event_uuid` is useful for debugging and external logs.
- `trip_id` is present for trip-scoped records.
- `user_id` may be present for user-scoped records.
- `access_revoked` events are targeted markers used when a removed member must
  clear inaccessible trip data.

Do not derive cursor pages only from `updated_at`; timestamp cursors are too
easy to make nondeterministic under concurrent writes.

## Deleted Records

Deleted synced records must appear in the sync feed.

`deleted_records` fields:

- `id` UUID primary key
- `entity_type`
- `entity_id`
- `trip_id`
- `user_id`
- `deleted_at`
- `revision`
- `deleted_by_user_id`
- `deleted_by_device_id`
- `reason` (`deleted`, `access_revoked`, `parent_deleted`)
- `metadata` JSONB

Soft-delete syncable records so offline clients can learn about removals after
being offline.

Deleting a parent should create tombstones for dependent syncable child records
or create a parent tombstone plus explicit child tombstones in the pull
response. Prefer explicit child tombstones for deterministic client cleanup.

## Cursor Semantics

Pull endpoint:

```text
GET /api/v1/sync?cursor=...
```

Optional params:

- `cursor`
- `limit`, default 250, max 1000
- `scope`, default `default`

Cursor format:

- Treat cursor as opaque on the client.
- Encode version, last sync event ID, scope, and issued timestamp.
- Sign the cursor with Rails `MessageVerifier` or equivalent.
- Example decoded payload:

```json
{
  "v": 1,
  "last_event_id": 1242,
  "scope": "default",
  "issued_at": "2026-06-30T22:00:00Z"
}
```

Behavior:

- No cursor means initial pull.
- Initial pull returns all active records visible to the user, plus relevant
  tombstones needed to clear access-revoked or deleted records known to the
  server.
- Cursor pull returns events with `sync_events.id > last_event_id`, in ascending
  event ID order, filtered through current authorization.
- The server returns `next_cursor` pointing at the last event included in the
  response.
- If more events remain after `limit`, return `has_more: true`.
- The client should only advance its local cursor after fully applying the pull
  response.
- Repeating the same cursor should return the same logical page unless
  authorization changed. If authorization changed, access revocation tombstones
  take precedence.

Pull response shape:

```json
{
  "changes": [
    {
      "type": "trip",
      "id": "2b73d044-8a26-44a7-a42f-64e3f5e9f30d",
      "revision": 7,
      "updated_at": "2026-06-30T22:10:00Z",
      "attributes": {
        "title": "Austin to Marfa and Big Bend",
        "start_date": "2026-07-10",
        "end_date": "2026-07-13"
      }
    }
  ],
  "deleted_records": [
    {
      "entity_type": "trip_stop",
      "entity_id": "5b3230e5-40d7-4b2c-9bb1-91c1b7481664",
      "server_id": "5b3230e5-40d7-4b2c-9bb1-91c1b7481664",
      "deleted_at": "2026-06-30T22:00:00Z",
      "revision": 9,
      "reason": "deleted"
    }
  ],
  "next_cursor": "opaque-signed-cursor",
  "has_more": false
}
```

Use `changes`, `deleted_records`, and `next_cursor` as the canonical response
keys. The earlier `records`/`deleted`/`cursor` names should not be used for the
client contract.

## Push Operations

Push endpoint:

```text
POST /api/v1/sync/operations
```

Request:

```json
{
  "operations": [
    {
      "operation_id": "local-op-001",
      "device_id": "srv-or-local-device-id",
      "entity_type": "trip_stop",
      "entity_id": "local-stop-abc",
      "action": "change_stop_kind",
      "base_revision": 4,
      "created_at": "2026-06-30T22:10:00Z",
      "payload": {
        "kind": "route_stop"
      }
    }
  ]
}
```

The current client may omit `device_id` on some queued operations. If omitted,
Rails should use the device associated with the current API session when
available. If no device can be determined, reject the operation with
`device_required`.

Never trust `user_id` from an operation body. If sent, ignore it or validate it
matches the authenticated user.

Idempotency:

- Treat `operation_id` as an idempotency key per device.
- Add unique index `[device_id, operation_id]` on `client_operations`.
- Repeating an already accepted operation returns the original result.
- Repeating an already rejected/conflicted operation returns the original
  result unless a later implementation explicitly supports retry replacement.

`client_operations` fields:

- `id` UUID primary key
- `operation_id`
- `device_id`
- `user_id`
- `entity_type`
- `entity_id`
- `action`
- `payload` JSONB
- `base_revision`
- `client_created_at`
- `received_at`
- `processed_at`
- `status`
- `result` JSONB
- `error_code`
- `message`

Push response:

```json
{
  "results": [
    {
      "operation_id": "local-op-001",
      "status": "accepted",
      "entity_type": "trip_stop",
      "entity_id": "local-stop-abc",
      "server_id": "5b3230e5-40d7-4b2c-9bb1-91c1b7481664",
      "revision": 5,
      "message": null,
      "mappings": []
    }
  ]
}
```

Process operations in request order. Prefer one database transaction per
operation so one rejected operation does not force unrelated valid operations to
fail. For aggregate operations with dependent nested records, process the
aggregate in one transaction.

## Operation Result States

States:

- `accepted`
- `rejected`
- `conflict`

Use `rejected` when the operation is malformed, invalid, unauthorized, refers to
missing required records, or cannot ever succeed as submitted.

Use `conflict` when the operation is well-formed and authorized but was based on
stale server state that the server should not merge automatically.

Conflict result shape:

```json
{
  "operation_id": "op-456",
  "status": "conflict",
  "entity_type": "trip_stop",
  "entity_id": "local-stop-abc",
  "server_id": "5b3230e5-40d7-4b2c-9bb1-91c1b7481664",
  "revision": 8,
  "message": "Trip stop changed on the server",
  "conflict": {
    "base_revision": 4,
    "current_revision": 8,
    "resolution": "pull_required"
  }
}
```

## Required Operation Actions

Rails must support both the explicit operation set from the plan and the current
iOS action names already present in `FieldAtlasOperationAction`.

### Current Client Actions

These are already in the iOS code and must work:

- `upsert_trip_workspace`
- `create_trip`
- `rename_trip`
- `delete_trip`
- `add_stop`
- `update_stop`
- `move_stop`
- `remove_stop`
- `add_route_waypoint`
- `remove_route_waypoint`
- `save_route_snapshot`

### Expanded Trip And Segment Actions

- `update_trip_dates`
- `create_segment`
- `update_segment`
- `delete_segment`

### Expanded Stop And Option Actions

- `create_stop`
- `change_stop_kind`
- `link_option`
- `unlink_option`
- `select_option`
- `unselect_option`

### Route Actions

- `delete_route_snapshot`

### Sharing Actions

- `create_trip_invite`
- `accept_trip_invite`
- `revoke_trip_invite`
- `remove_trip_member`
- `update_trip_member_role`

### Additional User Data Actions

Support these either as explicit actions or through generic upsert/delete
handlers that validate entity type and payload:

- `upsert_favorite_place`
- `delete_favorite_place`
- `create_place_list`
- `update_place_list`
- `delete_place_list`
- `add_place_list_item`
- `remove_place_list_item`
- `record_search_history_entry`
- `upsert_search_session`
- `delete_search_session`
- `upsert_user_setting`
- `delete_user_setting`
- `create_memory_asset`
- `update_memory_asset`
- `delete_memory_asset`
- `create_drive_session`
- `update_drive_session`
- `end_drive_session`
- `delete_drive_session`

## Aggregate Workspace Operation

`upsert_trip_workspace` is required because the current iOS repository enqueues
it after saving the structured local workspace.

Behavior:

- `entity_type`: `trip`
- `entity_id`: client local trip/workspace ID
- Payload contains the encoded trip workspace, and may contain nested segments,
  stops, option links, and route snapshots depending on client encoding.
- Rails should normalize the payload into `trips`, `trip_segments`,
  `trip_stops`, `trip_stop_option_links`, and route tables.
- Rails should preserve unknown client-specific details in `client_payload`.
- Rails should return mappings for the trip and every nested record whose local
  ID differs from its server UUID.
- Rails should tombstone child records that existed on the server but are absent
  from a full authoritative workspace payload, unless the payload declares
  itself partial.

This operation is the safest bridge while the client shifts from whole-workspace
persistence to finer-grained operations. Do not omit it.

## Revision And Conflict Policy

Every syncable record returns a monotonically increasing `revision`.

The client sends `base_revision` when it has one. Rails compares the base
revision to the current record revision.

Rules:

- `base_revision` is required for updates/deletes to existing server records.
- `base_revision` may be null for creates and aggregate bootstrap operations.
- If current revision equals `base_revision`, validate and apply the operation.
- If the record is already in the requested final state, return `accepted` as an
  idempotent success.
- If the operation is stale and changes a field that has changed on the server,
  return `conflict`.
- If the operation is unauthorized, return `rejected`, not `conflict`.
- If the target record was deleted, return `conflict` for stale updates and
  idempotent `accepted` for repeated deletes by an authorized user.

Initial conservative merge policy:

- Trip title/date updates conflict on stale revision unless final values already
  match.
- Segment title/date/sort/color updates conflict on stale revision unless final
  values already match.
- Stop title, notes, kind, segment assignment, coordinates, and sort updates
  conflict on stale revision unless final values already match.
- Option selection conflicts if the parent option group changed since
  `base_revision`.
- Route snapshot saves are accepted if well-formed, but marked `stale` when the
  route signature does not match current route-affecting trip state.
- Membership role changes conflict if the membership changed since
  `base_revision`.

## Authorization Rules

All sync requests require a valid API session.

Push operations validate:

- Bearer session token.
- Registered device or session-associated device.
- Entity type is supported.
- Operation action is supported for entity type.
- Payload shape.
- Trip membership.
- Member role.
- Base revision.

Read access:

- User-scoped records are visible only to their owning user.
- Trip-scoped records are visible to active trip members.
- Removed members receive access-revoked tombstones and then no longer receive
  trip records.

Write access:

- Owner: all trip mutations, invite management, membership management.
- Editor: trip planning mutations, route snapshot mutations, option mutations.
- Viewer: no planning mutations.
- Removed: no reads or writes.

## Realtime Sync Hints

Rails may send APNs or websocket hints when trip data changes.

Hints should only tell the client to run sync. Canonical data still comes from
the sync API.

The backend should not require realtime delivery for correctness.

Initial hint payload can be tiny:

```json
{
  "type": "sync_hint",
  "scope": "default",
  "trip_id": "2b73d044-8a26-44a7-a42f-64e3f5e9f30d"
}
```

## Rails Architecture

Keep controllers thin. Put sync behavior behind service objects.

Suggested controllers:

- `Api::V1::Auth::AppleController`
- `Api::V1::Auth::RefreshController`
- `Api::V1::Auth::SessionsController`
- `Api::V1::MeController`
- `Api::V1::DevicesController`
- `Api::V1::SyncController`
- `Api::V1::SyncOperationsController`
- `Api::V1::TripInvitesController`
- `Api::V1::TripMembersController`

Suggested services:

- `Auth::AppleIdentityVerifier`
- `Auth::SessionIssuer`
- `Auth::TokenDigest`
- `Devices::Registrar`
- `Sync::Cursor`
- `Sync::Pull`
- `Sync::OperationProcessor`
- `Sync::OperationResult`
- `Sync::RecordSerializer`
- `Sync::EventRecorder`
- `Sync::DeletedRecordRecorder`
- `Sync::AccessScope`
- `Sync::Operations::UpsertTripWorkspace`
- `Sync::Operations::CreateTrip`
- `Sync::Operations::UpdateTrip`
- `Sync::Operations::DeleteTrip`
- `Sync::Operations::CreateOrUpdateSegment`
- `Sync::Operations::CreateOrUpdateStop`
- `Sync::Operations::MoveStop`
- `Sync::Operations::OptionLink`
- `Sync::Operations::SaveRouteSnapshot`
- `Sync::Operations::Invite`
- `Sync::Operations::Member`
- `Sync::Operations::GenericUserDataUpsert`

Serializers should be shared by request tests and contract fixture generation.
Avoid hand-building each sync response in controllers.

## Contract Fixtures

Maintain checked JSON fixtures under a predictable test fixture directory.

Required fixtures:

- Apple auth response.
- Refresh response.
- `GET /api/v1/me` response.
- Device registration response.
- Device update response.
- Sync pull initial response with all required record families.
- Sync pull incremental response.
- Sync pull access-revoked response.
- Sync push accepted response.
- Sync push rejected response.
- Sync push conflict response.
- `upsert_trip_workspace` accepted response with mappings.
- Invite create response.
- Invite lookup response.
- Invite accept response.
- Member remove response.

The iOS app should be able to decode these fixtures without a live Rails server.

## Backend Test Plan

Write backend tests from the beginning. The iOS client will rely on stable
contracts and fixtures.

### Model Tests

- Users can be created independently of Apple auth.
- Apple identities attach to users.
- API sessions store token digests and can be revoked.
- Devices belong to users and upsert by client device ID.
- Trips can be private or shared through memberships.
- Creating a trip creates an owner membership.
- Membership roles enforce owner/editor/viewer rules.
- Invites carry token, URL, status, inviter, accepted user, role, expiration,
  and accepted timestamp.
- `trip_stops.kind` accepts `idea`, `route_stop`, `possible_stop`, `waypoint`,
  and `note`.
- `open_idea` and `route_waypoint` aliases normalize at the API boundary.
- Option links associate two `trip_stops` rows from the same trip.
- Route snapshots store route legs and steps separately from editable stops.
- Favorite places, place lists, search records, settings, memory assets, and
  drive sessions have revisions and tombstones.
- Soft-deleted records produce deleted markers.
- Sync events are appended for accepted create/update/delete mutations.

### Request Tests

- `POST /api/v1/auth/apple` returns user and API session data.
- Apple auth creates a user on first sign-in.
- Apple auth reuses the user on later sign-ins with the same Apple subject.
- `POST /api/v1/auth/refresh` rotates session metadata.
- `DELETE /api/v1/auth/session` invalidates the session.
- `GET /api/v1/me` returns the authenticated user.
- Authenticated endpoints reject missing/invalid bearer tokens.
- `POST /api/v1/devices` registers or updates a device.
- `PATCH /api/v1/devices/:id` updates device metadata.
- `GET /api/v1/sync?cursor=...` returns changed records and deleted markers.
- `GET /api/v1/sync` initial pull returns every visible active record family.
- `POST /api/v1/sync/operations` returns accepted, rejected, and conflict
  operation results.
- Invite create, lookup, accept, revoke, member role update, and member removal
  endpoints enforce access rules.

### Sync Tests

- Operation IDs are idempotent per device.
- Replayed accepted operations return the original accepted result.
- Accepted create operations return server IDs and revisions.
- Accepted aggregate workspace operations return nested mappings.
- Accepted update operations increment revisions.
- Stale `base_revision` returns conflict when the update cannot be safely
  applied.
- Unauthorized operations return rejected and do not mutate records.
- Malformed operations return rejected and do not mutate records.
- Pull sync returns records changed after the provided cursor.
- Pull sync returns tombstones for deleted records.
- Cursor advancement is deterministic and stable across repeated requests.
- `limit` and `has_more` paginate by sync event ID.
- Shared trip records appear for active members.
- Shared trip records do not appear for removed members.
- Removed members receive access-revoked tombstones.
- Route-affecting edits mark snapshots stale.
- Saving a route snapshot stores snapshot stops, legs, and steps.
- Non-trip user-data records sync through the same event/cursor path.

### Contract Fixture Tests

- Fixtures are generated by the same serializers used in controllers.
- Fixtures decode as valid JSON.
- Fixture shapes match documented endpoint contracts.
- Push and pull fixtures include every required entity type.
- Conflict fixtures include `base_revision`, `current_revision`, and
  `resolution`.

## Internal Build Sequence

This can be developed in phases, but the branch should land as one complete API
surface.

### Phase 1: UUID And Auth Foundation

- Add UUID support for new sync tables.
- Add users and auth identities.
- Add API sessions with token digests.
- Add Apple identity verifier service.
- Add auth endpoints and tests.

### Phase 2: Devices

- Add devices table.
- Add device register/update endpoints.
- Associate sessions with devices when possible.

### Phase 3: Core Trip Schema

- Add trips, members, invites, segments, stops, option links, route snapshots,
  route snapshot stops, legs, and steps.
- Add model validations and indexes.
- Add role/access helpers.

### Phase 4: Additional User Data Schema

- Add favorite places, place lists, place list items, search history entries,
  search sessions, search result snapshots, user settings, memory assets, and
  drive sessions.
- Add structured key columns and JSONB payload preservation.

### Phase 5: Sync Infrastructure

- Add client operations.
- Add sync events.
- Add deleted records.
- Add signed cursor encoding/decoding.
- Add record serializers.
- Add pull sync.

### Phase 6: Operation Processing

- Add operation dispatcher.
- Add idempotency handling.
- Add current client actions.
- Add expanded explicit trip/segment/stop/option/route/share actions.
- Add generic user-data upsert/delete actions.
- Add conflict handling.

### Phase 7: Invites And Collaboration Endpoints

- Add invite create/lookup/accept/revoke behavior.
- Add member remove and role update behavior.
- Add access-revoked tombstones for removed members.

### Phase 8: Contract Fixtures And Full Verification

- Add request/model/sync/fixture tests.
- Generate fixture JSON.
- Coordinate fixture decoding with the iOS app.

## Backend Acceptance Criteria

- iOS can authenticate with Sign in with Apple.
- Rails creates first-party users and Apple auth identities.
- Rails can refresh and revoke API sessions.
- iOS can register and update a device.
- iOS can create and sync trips.
- iOS can push pending trip operations.
- iOS can push `upsert_trip_workspace`.
- iOS can pull changes by opaque signed cursor.
- Rails returns UUID server IDs and revisions for all syncable records.
- Accepted create operations return local-to-server mappings.
- Deleted records appear in sync responses.
- Cursor pulls are deterministic and paginated.
- Ideas, route stops, possible stops, route waypoints, and notes are represented
  by one `trip_stops` resource with mutable `kind`.
- Rails supports the current iOS stop-kind values and normalizes older aliases.
- Option groups are represented by association records between `trip_stops`.
- Route snapshots are stored separately from editable trip data.
- Route snapshot stops, legs, and steps sync with route snapshots.
- Private and shared trips use the same trip storage model.
- Membership and invite APIs support collaborative trip planning.
- Removed members lose access to shared trip data.
- Removed members receive tombstones/access-revoked markers on sync.
- Favorite places, place lists, search history/sessions, settings, memory
  assets, and drive sessions are included in the sync system.
- Push or websocket hints can trigger client sync but are not required for
  correctness.
- Backend tests cover auth, devices, sync, revisions, tombstones, stop kinds,
  option links, route snapshots, sharing, authorization, user-data records, and
  contract fixtures.

## Decisions Assumed By This Plan

- New syncable backend records use UUID public IDs.
- Public sync revisions use explicit `revision` columns, not Rails
  `lock_version`.
- Cursor pull uses append-only `sync_events`, not timestamp-only queries.
- Cursor values are opaque and signed.
- Sign in with Apple is the primary account creation path, but users are not
  Apple-specific.
- `upsert_trip_workspace` is required for the current iOS data layer.
- The backend first delivery includes all user-data record families already in
  the iOS SQLite schema.

## Decisions To Confirm Before Implementation

- Universal Link host and invite URL path.
- Apple token audience values: bundle ID, Services ID, or both.
- Access token and refresh token lifetimes.
- Whether APNs sync hints are required in the first production deploy or can
  follow after pull/push correctness.
- Exact route polyline encoding the client will send for `encoded_polyline` and
  `client_payload`.
