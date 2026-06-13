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

No fake seed places are created. Source records are persisted only from real provider responses or future explicit import tasks.
