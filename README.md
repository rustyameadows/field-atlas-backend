# Field Atlas Backend

Modern Rails backend for Field Atlas places, source records, and provider-backed search.

This is a full Rails app with ERB views, Hotwire, Importmap, Propshaft, Active Storage, and Solid adapters. It intentionally does not use React, Next.js, Tailwind, Bootstrap, or another CSS framework.

## Local Setup

Requirements:

- Ruby 3.4.4
- PostgreSQL 18 on port 55432 for local development, or another PostgreSQL server with PostGIS available
- PostGIS 3.6+

Setup:

```bash
bundle install
PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH bin/rails db:prepare
bin/rails test
```

The app defaults development/test database connections to `localhost:55432` so it can use Homebrew's current PostGIS package without replacing an existing PostgreSQL 16 service. Override with `DATABASE_HOST` and `DATABASE_PORT` if your local PostGIS server runs elsewhere.

### Local PostGIS Troubleshooting

If Rails raises `ActiveRecord::ConnectionNotEstablished` with `connection to server at "127.0.0.1", port 55432 failed: Connection refused`, the app is running but the expected PostgreSQL 18/PostGIS server is not listening on `localhost:55432`. This usually means Homebrew `postgresql@18` is stopped or its cluster is still configured for the default `5432` port.

Fix the local service, not the Rails app: configure `/opt/homebrew/var/postgresql@18/postgresql.conf` with `port = 55432`, start `postgresql@18`, then run `PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH bin/rails db:prepare`. Do not point this app at an older PostgreSQL 16 database on `5432` unless that server has the required PostGIS extension and schema.

Production is still env-driven for Render later: Rails will use `DATABASE_URL`, and PostGIS is enabled by the places migration.

Run for the iOS Simulator:

```bash
NPS_API_KEY=your_key_here bin/rails server -p 3000
```

Use `http://127.0.0.1:3000` from the iOS Simulator. For a physical device, bind to the local network:

```bash
NPS_API_KEY=your_key_here bin/rails server -b 0.0.0.0 -p 3000
```

## Render Deployment

The app is prepared for a Git-backed Render Blueprint using
[`render.yaml`](render.yaml). The Blueprint provisions one Ruby web service and
one PostgreSQL/PostGIS database. Solid Cache, Solid Queue, and Solid Cable use
the primary database tables created by the normal Rails migrations.

Before deploying, commit and push the Blueprint to the branch Render should
deploy. Then open:

```text
https://dashboard.render.com/blueprint/new?repo=https://github.com/rustyameadows/field-atlas-backend
```

In the Render Dashboard, fill the secret env vars marked `sync: false`:

- `RAILS_MASTER_KEY`
- `NPS_API_KEY`
- `CLOUDFLARE_R2_ACCOUNT_ID`
- `CLOUDFLARE_R2_ACCESS_KEY_ID`
- `CLOUDFLARE_R2_SECRET_ACCESS_KEY`
- `CLOUDFLARE_R2_BUCKET`

The Blueprint also sets the public web/API base URLs and non-secret Sign in
with Apple values for the native iOS app:

- `FIELD_ATLAS_WEB_BASE_URL=https://field-atlas.com`
- `FIELD_ATLAS_API_BASE_URL=https://api.field-atlas.com`
- `APPLE_CLIENT_ID=com.rustymeadows.DestinationApp`
- `APPLE_ISSUER=https://appleid.apple.com`
- `APPLE_JWKS_URL=https://appleid.apple.com/auth/keys`

This backend validates the native app's Apple identity token directly. It does
not exchange Apple authorization codes yet, so a Services ID, web redirect URL,
`APPLE_TEAM_ID`, `APPLE_KEY_ID`, and `APPLE_PRIVATE_KEY` are not required for
the current native iOS flow.

The web service uses `/up` as its health check. The free-compatible build path
runs `bin/render-build.sh`, which installs gems, precompiles assets, and runs
database migrations.

## Asset Uploads API

User media and files use Cloudflare R2 direct uploads. Rails stores asset
metadata and generic links to app objects; uploaded bytes go directly from the
iOS app to R2 using short-lived presigned URLs.

Create an upload intent:

```bash
curl -X POST "http://127.0.0.1:3000/api/v1/assets/upload_intents" \
  -H "Authorization: Bearer $FIELD_ATLAS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"asset":{"client_id":"local-asset-1","asset_kind":"image","mime_type":"image/jpeg","original_filename":"trail.jpg","byte_size":12345},"links":[{"attachable_type":"Trip","attachable_id":"trip-server-id","role":"cover"}]}'
```

The response includes `asset`, `links`, and an `upload` object with a `PUT` URL
and required headers. After the app uploads the bytes to R2, complete the asset:

```bash
curl -X POST "http://127.0.0.1:3000/api/v1/assets/$ASSET_ID/complete" \
  -H "Authorization: Bearer $FIELD_ATLAS_ACCESS_TOKEN"
```

Download URLs are intentionally separate from sync responses because they
expire:

```bash
curl -X POST "http://127.0.0.1:3000/api/v1/assets/download_intents" \
  -H "Authorization: Bearer $FIELD_ATLAS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"asset_ids":["asset-server-id"]}'
```

Supported link targets for v1 are `Trip`, `TripStop`, `PlaceList`,
`PlaceListItem`, `FavoritePlace`, `Place`, and `DriveSession`. Visibility is
resolved from the linked app object. A user can attach their own asset to a
canonical `Place`; that does not make the asset public or editorial.

## Places API

Place category conventions live in
[`docs/PLACE_CATEGORY_GUIDANCE.md`](docs/PLACE_CATEGORY_GUIDANCE.md).

Search:

```bash
curl "http://127.0.0.1:3000/api/v1/search?q=pinnacles&sources=nps"
```

Supported params:

- `q` or `query`
- `bbox=min_lng,min_lat,max_lng,max_lat`
- `center_lat`, `center_lng`, `radius_meters`
- `sources=field_atlas,nps`
- `types=park_unit,nps_place,campground,visitor_center`
- `limit`

Place options:

```bash
curl "http://127.0.0.1:3000/api/v1/place_options"
```

Returns the server-owned `kind` values the admin app should use when creating
canonical places.

Create a canonical place:

```bash
curl -X POST "http://127.0.0.1:3000/api/v1/places" \
  -H "Content-Type: application/json" \
  -d '{"place":{"name":"Hidden Valley Picnic Area","kind":"poi","primary_category":"picnic_area","coordinate":{"lat":34.0124,"lng":-116.167}},"associations":[{"provider":"mapkit","identifiers":[{"identifier":"abc123","identifier_kind":"primary"}]}]}'
```

The create endpoint accepts either top-level JSON fields or a wrapped
`place` object. If `slug` is omitted, the backend generates one from `name`.
If `status` is omitted, the backend creates a published place; pass
`"status":"draft"` only when the place should stay hidden from normal app
use. The request may include `associations`, using the same `provider` plus
`identifiers` shape as the external-identifier endpoint. The response returns
the canonical place `id`, normalized fields, `coordinate`, and `source_ids`.
If an association is invalid or already belongs to another place, the whole
create request fails and no canonical place is created.

Canonical place external identifiers:

```bash
curl -X POST "http://127.0.0.1:3000/api/v1/place_external_identifiers" \
  -H "Content-Type: application/json" \
  -d '{"place_id":123,"provider":"mapkit","identifiers":[{"identifier":"abc123","identifier_kind":"primary"}]}'
```

External identifiers are verified crosswalks from providers such as MapKit, NPS,
or BLM to canonical Field Atlas places. The backend stores provider IDs for
matching and enrichment; it does not store full MapKit POI search responses.

## NPS Canonical Imports

Run the Phase 1 NPS import to sync all NPS park units from the API, then import
campgrounds and visitor centers as canonical places under those parks:

```bash
NPS_API_KEY=your_key_here bin/rails places:import_nps_phase1
```

The import is rerunnable. It upserts NPS source records by provider source ID,
promotes parks, campgrounds, and visitor centers into canonical places, links
them with `PlaceSourceLink`, and creates `PlaceContainment` for campgrounds and
visitor centers under their parent park. Child records whose `parkCode` does not
match a canonical NPS park are skipped and printed in the task output.

No fake seed places are created. Source records are persisted only from real provider responses or future explicit import tasks.
