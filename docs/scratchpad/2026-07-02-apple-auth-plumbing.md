# 2026-07-02 Apple Auth Plumbing

## Goal

Finish the native Sign in with Apple backend path for the iOS bundle ID
`com.rustymeadows.DestinationApp`.

## Decisions

- Validate Apple identity tokens directly against Apple JWKS.
- Use `APPLE_CLIENT_ID` as the preferred audience env var, with
  `APPLE_AUTH_AUDIENCE` retained as a fallback.
- Keep `authorization_code` accepted but unused for v1.
- Do not require nonce until the iOS app sends one.
- Keep existing auth response fields for client compatibility.

## Current Status

- Added verifier tests for signed JWT validation, bad issuer/audience, expiry,
  missing subject, and JWKS rotation.
- Updated local/test Apple auth fakes to use `identity_token` as `sub`.
- Updated integration tests so user identity is keyed by Apple subject, not
  email.

## Verification

- Focused auth tests pass.
- `bin/rails test test/services` passes: 16 runs, 95 assertions.
- `bin/rails test test/integration/field_atlas_data_api_test.rb` passes: 12 runs, 108 assertions.
- `PARALLEL_WORKERS=1 bin/rails test` passes: 76 runs, 412 assertions.
