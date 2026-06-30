# Place Category Guidance

## Current Rule

`kind` is the broad system shape. It controls how the backend and app reason
about a place.

`primary_category` is the more specific human-facing category slug. It should
describe what the place is, not repeat the broad kind when better information
exists.

For example:

```json
{
  "kind": "park_unit",
  "primary_category": "national_park"
}
```

This is better than:

```json
{
  "kind": "park_unit",
  "primary_category": "park_unit"
}
```

## Slug Style

Use lowercase snake_case slugs:

- `national_park`
- `national_monument`
- `national_historic_site`
- `national_historical_park`
- `national_preserve`
- `national_recreation_area`
- `park`

Use display labels in the app by titleizing the slug or through a future label
map. Do not store display labels like `National Park` in `primary_category`.

## NPS Park Units

For canonical places created from NPS park records, use the NPS designation when
it is clear:

- `National Park` -> `national_park`
- `National Monument` -> `national_monument`
- `National Historic Site` -> `national_historic_site`
- `National Historical Park` -> `national_historical_park`
- `National Historic Trail` -> `national_historic_trail`
- `National Preserve` -> `national_preserve`
- `National Recreation Area` -> `national_recreation_area`
- `National Reserve` -> `national_reserve`
- `National Memorial` -> `national_memorial`
- `National Park & Preserve` -> `national_park_and_preserve`
- `National and State Parks` -> `national_and_state_parks`
- `National Parks` -> `national_parks`
- `Park` or park-like names with blank designation -> `park`

## Admin Create Guidance

For now, admin create flows only need `name` and `kind`.

Send `primary_category` only when the category is known and deliberate. Do not
guess from fuzzy text input, and do not auto-create new category values from
user submissions.
