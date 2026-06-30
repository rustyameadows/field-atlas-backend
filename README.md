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

Production is still env-driven for Render later: Rails will use `DATABASE_URL`, and PostGIS is enabled by the places migration.

Run for the iOS Simulator:

```bash
NPS_API_KEY=your_key_here bin/rails server -p 3000
```

Use `http://127.0.0.1:3000` from the iOS Simulator. For a physical device, bind to the local network:

```bash
NPS_API_KEY=your_key_here bin/rails server -b 0.0.0.0 -p 3000
```

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
