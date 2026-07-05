# Public Profiles

## Goal

Add app-owned public profile fields to users: editable display name, username,
bio, and a public profile photo asset reference.

## Decisions

- `users.display_name` remains the app/public display name.
- Apple/provider display names are preserved on `user_auth_identities` and only
  seed `users.display_name` when it is blank.
- Usernames are stored exactly as sent by the client, except blank values clear
  the field.
- Profile photos reuse ready image `Asset` records uploaded by the same user.
- Public profile photo downloads are available to any authenticated user through
  the existing download intent flow.

## Verification

- Baseline targeted tests passed before implementation.
- Added failing tests for model validation, profile API updates, public profile
  reads, public profile photo downloads, and dashboard columns.
- Targeted model, integration, dashboard, and fixture tests are passing.
- Full verification remains: `bin/rails test`.
