# NPS Phase 1 Import Scratchpad

## Goal

Implement a rerunnable NPS API import for all park units, then canonicalize
campgrounds and visitor centers under those parks.

## Current Findings

- Current DB has 51 NPS park `SourceRecord`s and 51 linked NPS park source
  links, so it is not a complete NPS park unit sync.
- Stored child source records already exist locally: 73 campgrounds and 62
  visitor centers.
- Current search persists live child records and creates `PlaceContainment` for
  within-park searches, but does not promote those records to canonical
  `Place`s.
- `NPS_API_KEY` is not present in this shell, so real import execution will need
  that env var later.

## Implementation Direction

- Add an API-backed, paginated importer service.
- Reuse existing `SourceRecordUpsert` and NPS normalization.
- Keep parks synced before child promotion.
- Promote campgrounds and visitor centers by NPS source ID only.
- Skip/report children whose `parkCode` has no canonical parent after park sync.

## Status

- Added tests for pagination, idempotency, missing parent skips, and canonical
  search results.
- Implemented importer, child promotion, search containment serialization, and
  `places:import_nps_phase1` task.
