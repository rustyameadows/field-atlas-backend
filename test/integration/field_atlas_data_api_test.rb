require "test_helper"

class FieldAtlasDataApiTest < ActionDispatch::IntegrationTest
  setup do
    @auth_payload = {
      identity_token: "test.identity.token",
      authorization_code: "test-auth-code",
      full_name: "Avery Field",
      email: "avery@example.com",
      device_name: "Avery's iPhone"
    }
  end

  test "apple auth creates a user session and device can be registered" do
    post "/api/v1/auth/apple", params: @auth_payload, as: :json

    assert_response :success
    auth = response.parsed_body
    assert_equal "Avery Field", auth.dig("user", "display_name")
    assert_equal "avery@example.com", auth.dig("user", "email")
    assert_match(/\A[0-9a-f-]{36}\z/, auth.dig("user", "id"))
    assert auth.dig("session", "access_token").present?
    assert auth.dig("session", "refresh_token").present?

    token = auth.dig("session", "access_token")
    post "/api/v1/devices", params: {
      device_id: "local-device-1",
      name: "Avery's iPhone",
      platform: "ios",
      app_version: "1.0",
      build_number: "100"
    }, headers: bearer(token), as: :json

    assert_response :created
    device = response.parsed_body.fetch("device")
    assert_match(/\A[0-9a-f-]{36}\z/, device.fetch("id"))
    assert_equal "local-device-1", device.fetch("client_device_id")
    assert_equal "ios", device.fetch("platform")

    get "/api/v1/me", headers: bearer(token), as: :json

    assert_response :success
    assert_equal auth.dig("user", "id"), response.parsed_body.dig("user", "id")
  end

  test "sync operations accept a workspace and pull returns canonical changes" do
    token = authenticated_token
    device_id = register_device(token).fetch("id")

    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-workspace-1",
          device_id: device_id,
          entity_type: "trip",
          entity_id: "local-trip-1",
          action: "upsert_trip_workspace",
          base_revision: nil,
          created_at: "2026-06-30T22:10:00Z",
          payload: {
            id: "local-trip-1",
            title: "Austin to Marfa",
            startDate: "2026-07-10",
            endDate: "2026-07-13",
            segments: [
              { id: "local-segment-1", title: "Day 1", sortKey: 1.0 }
            ],
            stops: [
              {
                id: "local-stop-1",
                segmentID: "local-segment-1",
                kind: "route_waypoint",
                title: "Lost Mine Trail",
                latitude: 29.2706,
                longitude: -103.3019,
                sortKey: 1.0
              }
            ],
            optionLinks: [
              {
                id: "local-option-1",
                groupID: "group-1",
                parentStopID: "local-stop-1",
                candidateStopID: "local-stop-1",
                groupTitle: "Choose hike",
                isSelected: true,
                sortKey: 1.0
              }
            ]
          }
        }
      ]
    }, headers: bearer(token), as: :json

    assert_response :success
    result = response.parsed_body.fetch("results").first
    assert_equal "accepted", result.fetch("status")
    assert_equal "local-trip-1", result.fetch("entity_id")
    assert_match(/\A[0-9a-f-]{36}\z/, result.fetch("server_id"))
    assert result.fetch("mappings").any? { |mapping| mapping["entity_type"] == "trip_stop" && mapping["entity_id"] == "local-stop-1" }

    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-workspace-1",
          device_id: device_id,
          entity_type: "trip",
          entity_id: "local-trip-1",
          action: "upsert_trip_workspace",
          created_at: "2026-06-30T22:10:00Z",
          payload: {}
        }
      ]
    }, headers: bearer(token), as: :json

    assert_response :success
    replay = response.parsed_body.fetch("results").first
    assert_equal result.fetch("server_id"), replay.fetch("server_id")
    assert_equal "accepted", replay.fetch("status")

    get "/api/v1/sync", headers: bearer(token), as: :json

    assert_response :success
    pull = response.parsed_body
    assert pull.fetch("next_cursor").present?
    assert_equal false, pull.fetch("has_more")
    assert pull.fetch("changes").any? { |record| record["type"] == "trip" && record.dig("attributes", "title") == "Austin to Marfa" }
    assert pull.fetch("changes").any? { |record| record["type"] == "trip_stop" && record.dig("attributes", "kind") == "waypoint" }
  end

  test "invite acceptance creates membership and removed member receives tombstone" do
    owner_token = authenticated_token(email: "owner@example.com", full_name: "Owner Field")
    owner_device = register_device(owner_token, local_id: "owner-device").fetch("id")
    trip_id = create_trip(owner_token, owner_device)

    post "/api/v1/trips/#{trip_id}/invites", params: {
      role: "editor",
      expires_in_seconds: 86_400
    }, headers: bearer(owner_token), as: :json

    assert_response :created
    invite = response.parsed_body.fetch("invite")
    assert_equal "pending", invite.fetch("status")
    assert invite.fetch("url").include?(invite.fetch("token"))

    guest_token = authenticated_token(email: "guest@example.com", full_name: "Guest Field")
    get "/api/v1/invites/#{invite.fetch("token")}", as: :json
    assert_response :success
    assert_equal "Austin to Marfa", response.parsed_body.dig("invite", "trip_title")

    post "/api/v1/invites/#{invite.fetch("token")}/accept", headers: bearer(guest_token), as: :json
    assert_response :success
    member = response.parsed_body.fetch("member")
    assert_equal "editor", member.fetch("role")

    delete "/api/v1/trips/#{trip_id}/members/#{member.fetch("id")}", headers: bearer(owner_token), as: :json
    assert_response :success
    assert_equal "removed", response.parsed_body.dig("member", "status")

    get "/api/v1/sync", headers: bearer(guest_token), as: :json
    assert_response :success
    assert response.parsed_body.fetch("deleted_records").any? { |record| record["reason"] == "access_revoked" && record["entity_type"] == "trip" }
  end

  test "refresh rotates a session and revoke invalidates it" do
    post "/api/v1/auth/apple", params: @auth_payload, as: :json
    assert_response :success
    auth = response.parsed_body

    post "/api/v1/auth/refresh", params: {
      refresh_token: auth.dig("session", "refresh_token")
    }, as: :json
    assert_response :success
    refreshed = response.parsed_body
    refute_equal auth.dig("session", "access_token"), refreshed.dig("session", "access_token")

    delete "/api/v1/auth/session", headers: bearer(refreshed.dig("session", "access_token")), as: :json
    assert_response :no_content

    get "/api/v1/me", headers: bearer(refreshed.dig("session", "access_token")), as: :json
    assert_response :unauthorized
  end

  test "generic user data operations sync through the cursor pull" do
    token = authenticated_token
    device_id = register_device(token).fetch("id")

    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-favorite-1",
          device_id: device_id,
          entity_type: "favorite_place",
          entity_id: "local-favorite-1",
          action: "upsert_favorite_place",
          payload: {
            id: "local-favorite-1",
            placeID: "place:123",
            name: "Pinnacles",
            encodedPlace: { title: "Pinnacles" }
          }
        },
        {
          operation_id: "op-setting-1",
          device_id: device_id,
          entity_type: "user_setting",
          entity_id: "distance_units",
          action: "upsert_user_setting",
          payload: {
            key: "distance_units",
            value: "miles"
          }
        }
      ]
    }, headers: bearer(token), as: :json

    assert_response :success
    assert_equal [ "accepted", "accepted" ], response.parsed_body.fetch("results").map { |result| result.fetch("status") }

    get "/api/v1/sync", headers: bearer(token), as: :json
    assert_response :success
    changes = response.parsed_body.fetch("changes")
    assert changes.any? { |record| record["type"] == "favorite_place" && record.dig("attributes", "place_id") == "place:123" }
    assert changes.any? { |record| record["type"] == "user_setting" && record.dig("attributes", "key") == "distance_units" }
  end

  test "route snapshots store child stops legs and steps" do
    token = authenticated_token
    device_id = register_device(token).fetch("id")
    trip_id = create_workspace(token, device_id)

    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-route-1",
          device_id: device_id,
          entity_type: "route_snapshot",
          entity_id: "local-route-1",
          action: "save_route_snapshot",
          payload: {
            id: "local-route-1",
            trip_id: trip_id,
            segmentID: "local-segment-1",
            provider: "apple-mapkit",
            totalDistanceMeters: 1200,
            expectedTravelTime: 600,
            routingSignature: { hash: "abc" },
            encodedRoute: { summary: "Trail drive" },
            snapshotStops: [
              { id: "local-snapshot-stop-1", tripStopID: "local-stop-1", kind: "route_stop", title: "Lost Mine", sortKey: 1 }
            ],
            legs: [
              {
                id: "local-leg-1",
                sourceStopID: "local-stop-1",
                destinationStopID: "local-stop-1",
                distanceMeters: 1200,
                expectedTravelTime: 600,
                steps: [
                  { id: "local-step-1", instructions: "Continue", distanceMeters: 1200, sortKey: 1 }
                ]
              }
            ]
          }
        }
      ]
    }, headers: bearer(token), as: :json

    assert_response :success
    result = response.parsed_body.fetch("results").first
    assert_equal "accepted", result.fetch("status")
    assert result.fetch("mappings").any? { |mapping| mapping["entity_type"] == "route_step" && mapping["entity_id"] == "local-step-1" }

    get "/api/v1/sync", headers: bearer(token), as: :json
    assert_response :success
    route = response.parsed_body.fetch("changes").find { |record| record["type"] == "route_snapshot" }
    assert_equal "apple-mapkit", route.dig("attributes", "provider")
    assert_equal "Continue", route.dig("attributes", "legs").first.dig("steps").first.fetch("instructions")
  end

  test "operation push returns rejected and conflict states" do
    token = authenticated_token
    device_id = register_device(token).fetch("id")
    trip_id = create_trip(token, device_id)

    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-unsupported-1",
          device_id: device_id,
          entity_type: "trip",
          entity_id: trip_id,
          action: "launch_rocket",
          payload: {}
        },
        {
          operation_id: "op-conflict-1",
          device_id: device_id,
          entity_type: "trip",
          entity_id: trip_id,
          action: "rename_trip",
          base_revision: 0,
          payload: { title: "Stale title" }
        }
      ]
    }, headers: bearer(token), as: :json

    assert_response :success
    rejected, conflict = response.parsed_body.fetch("results")
    assert_equal "rejected", rejected.fetch("status")
    assert_equal "unsupported_action", rejected.dig("error", "code")
    assert_equal "conflict", conflict.fetch("status")
    assert_equal "stale_revision", conflict.dig("conflict", "code")
  end

  test "collaboration operations can create accept update and remove members" do
    owner_token = authenticated_token(email: "op-owner@example.com", full_name: "Owner Field")
    owner_device = register_device(owner_token, local_id: "op-owner-device").fetch("id")
    trip_id = create_trip(owner_token, owner_device)

    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-invite-create-1",
          device_id: owner_device,
          entity_type: "trip_invite",
          entity_id: trip_id,
          action: "create_trip_invite",
          payload: { trip_id: trip_id, role: "editor" }
        }
      ]
    }, headers: bearer(owner_token), as: :json

    assert_response :success
    invite_result = response.parsed_body.fetch("results").first
    assert_equal "accepted", invite_result.fetch("status")
    invite = TripInvite.find(invite_result.fetch("server_id"))

    guest_token = authenticated_token(email: "op-guest@example.com", full_name: "Guest Field")
    guest_device = register_device(guest_token, local_id: "op-guest-device").fetch("id")
    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-invite-accept-1",
          device_id: guest_device,
          entity_type: "trip_invite",
          entity_id: invite.token,
          action: "accept_trip_invite",
          payload: { token: invite.token }
        }
      ]
    }, headers: bearer(guest_token), as: :json

    assert_response :success
    member_id = response.parsed_body.fetch("results").first.fetch("server_id")

    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-member-role-1",
          device_id: owner_device,
          entity_type: "trip_member",
          entity_id: member_id,
          action: "update_trip_member_role",
          payload: { role: "viewer" }
        },
        {
          operation_id: "op-member-remove-1",
          device_id: owner_device,
          entity_type: "trip_member",
          entity_id: member_id,
          action: "remove_trip_member",
          payload: {}
        }
      ]
    }, headers: bearer(owner_token), as: :json

    assert_response :success
    assert_equal [ "accepted", "accepted" ], response.parsed_body.fetch("results").map { |result| result.fetch("status") }

    get "/api/v1/sync", headers: bearer(guest_token), as: :json
    assert_response :success
    assert response.parsed_body.fetch("deleted_records").any? { |record| record["entity_type"] == "trip" && record["reason"] == "access_revoked" }
  end

  private

  def authenticated_token(email: "avery@example.com", full_name: "Avery Field")
    post "/api/v1/auth/apple", params: @auth_payload.merge(email: email, full_name: full_name), as: :json
    assert_response :success
    response.parsed_body.dig("session", "access_token")
  end

  def register_device(token, local_id: "local-device-1")
    post "/api/v1/devices", params: {
      device_id: local_id,
      name: local_id,
      platform: "ios",
      app_version: "1.0"
    }, headers: bearer(token), as: :json
    assert_response :created
    response.parsed_body.fetch("device")
  end

  def create_trip(token, device_id)
    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-trip-#{SecureRandom.hex(4)}",
          device_id: device_id,
          entity_type: "trip",
          entity_id: "local-trip-#{SecureRandom.hex(4)}",
          action: "upsert_trip_workspace",
          created_at: "2026-06-30T22:10:00Z",
          payload: { id: "local-trip", title: "Austin to Marfa" }
        }
      ]
    }, headers: bearer(token), as: :json
    assert_response :success
    response.parsed_body.fetch("results").first.fetch("server_id")
  end

  def create_workspace(token, device_id)
    post "/api/v1/sync/operations", params: {
      operations: [
        {
          operation_id: "op-workspace-#{SecureRandom.hex(4)}",
          device_id: device_id,
          entity_type: "trip",
          entity_id: "local-trip-#{SecureRandom.hex(4)}",
          action: "upsert_trip_workspace",
          payload: {
            id: "local-trip-route",
            title: "Austin to Marfa",
            segments: [
              { id: "local-segment-1", title: "Day 1", sortKey: 1.0 }
            ],
            stops: [
              { id: "local-stop-1", segmentID: "local-segment-1", kind: "route_stop", title: "Lost Mine Trail", sortKey: 1.0 }
            ]
          }
        }
      ]
    }, headers: bearer(token), as: :json
    assert_response :success
    response.parsed_body.fetch("results").first.fetch("server_id")
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
