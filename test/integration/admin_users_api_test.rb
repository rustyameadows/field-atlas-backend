require "test_helper"

class AdminUsersApiTest < ActionDispatch::IntegrationTest
  setup do
    @auth_payload = {
      identity_token: "test.identity.token",
      authorization_code: "test-auth-code",
      full_name: "Avery Field",
      email: "avery@example.com"
    }
  end

  test "admin can list users with profile photo stats and last seen" do
    admin_token = authenticated_token(email: "admin@example.com", full_name: "Admin Field")
    User.find_by!(email: "admin@example.com").update!(admin: true)

    user = User.create!(
      display_name: "Avery Field",
      username: "avery",
      email: "avery@example.com",
      admin: true,
      created_at: Time.zone.parse("2026-07-01T12:00:00Z")
    )
    asset = create_profile_photo(user)
    user.update!(profile_photo_asset: asset)

    Trip.create!(owner_user: user, title: "Open Trip")
    Trip.create!(owner_user: user, title: "Deleted Trip", deleted_at: Time.current)
    PlaceList.create!(user: user, name: "Open Map")
    PlaceList.create!(user: user, name: "Deleted Map", deleted_at: Time.current)
    Device.create!(user: user, client_device_id: "old-device", platform: "ios", last_seen_at: Time.zone.parse("2026-07-08T10:00:00Z"))
    Device.create!(user: user, client_device_id: "new-device", platform: "ios", last_seen_at: Time.zone.parse("2026-07-08T11:30:00Z"))
    Device.create!(user: user, client_device_id: "deleted-device", platform: "ios", last_seen_at: Time.zone.parse("2026-07-08T12:00:00Z"), deleted_at: Time.current)

    get "/api/v1/admin/users", params: { limit: 250 }, headers: bearer(admin_token), as: :json

    assert_response :success
    body = response.parsed_body
    row = body.fetch("users").find { |candidate| candidate.fetch("id") == user.id }

    assert_equal user.id, row.fetch("id")
    assert_equal "Avery Field", row.fetch("display_name")
    assert_equal "avery", row.fetch("username")
    assert_equal "avery@example.com", row.fetch("email")
    assert_equal asset.id, row.fetch("profile_photo_asset_id")
    assert_equal asset.id, row.dig("profile_photo_asset", "id")
    assert_equal "image", row.dig("profile_photo_asset", "asset_kind")
    assert_equal "image/jpeg", row.dig("profile_photo_asset", "mime_type")
    assert_equal 12_345, row.dig("profile_photo_asset", "byte_size")
    assert_equal "ready", row.dig("profile_photo_asset", "status")
    assert row.dig("profile_photo_asset", "updated_at").present?
    refute row.fetch("profile_photo_asset").key?("storage_key")
    assert_equal true, row.fetch("is_admin")
    assert_equal 1, row.fetch("trip_count")
    assert_equal 1, row.fetch("map_count")
    assert_equal "2026-07-01T12:00:00Z", row.fetch("created_at")
    assert_equal "2026-07-08T11:30:00Z", row.fetch("last_seen_at")
    assert_equal [ "users" ], body.keys
  end

  test "last seen key is present and null when user has no seen devices" do
    admin_token = authenticated_token(email: "admin-never@example.com", full_name: "Admin Never")
    User.find_by!(email: "admin-never@example.com").update!(admin: true)
    user = User.create!(display_name: "Never Seen", email: "never@example.com")

    get "/api/v1/admin/users", headers: bearer(admin_token), as: :json

    assert_response :success
    row = response.parsed_body.fetch("users").find { |candidate| candidate.fetch("id") == user.id }
    assert row.key?("last_seen_at")
    assert_nil row.fetch("last_seen_at")
    assert_equal 0, row.fetch("trip_count")
    assert_equal 0, row.fetch("map_count")
  end

  test "non admin users cannot list admin users" do
    token = authenticated_token(email: "viewer@example.com", full_name: "Viewer Field")

    get "/api/v1/admin/users", headers: bearer(token), as: :json

    assert_response :forbidden
    assert_equal "forbidden", response.parsed_body.dig("error", "code")
  end

  test "missing auth cannot list admin users" do
    get "/api/v1/admin/users", as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body.dig("error", "code")
  end

  test "limit caps at 250" do
    admin_token = authenticated_token(email: "admin-limit@example.com", full_name: "Admin Limit")
    User.find_by!(email: "admin-limit@example.com").update!(admin: true)
    260.times do |index|
      User.create!(
        display_name: "User #{index}",
        email: "user-#{index}@example.com",
        created_at: index.minutes.ago
      )
    end

    get "/api/v1/admin/users", params: { limit: 999 }, headers: bearer(admin_token), as: :json

    assert_response :success
    assert_equal 250, response.parsed_body.fetch("users").size
  end

  private

  def authenticated_token(email:, full_name:)
    post "/api/v1/auth/apple", params: @auth_payload.merge(
      identity_token: "apple-subject:#{email}",
      email: email,
      full_name: full_name
    ), as: :json
    assert_response :success
    response.parsed_body.dig("session", "access_token")
  end

  def create_profile_photo(user)
    Asset.create!(
      uploaded_by_user: user,
      asset_kind: "image",
      mime_type: "image/jpeg",
      byte_size: 12_345,
      storage_provider: "r2",
      storage_key: "user_uploads/#{user.id}/admin-profile.jpg",
      status: "ready",
      updated_at: Time.zone.parse("2026-07-08T12:00:00Z")
    )
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
