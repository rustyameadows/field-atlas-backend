require "test_helper"

class FieldAtlasContractFixturesTest < ActiveSupport::TestCase
  FIXTURE_DIR = "field_atlas_contract"
  REQUIRED_FIXTURES = %w[
    auth_apple_response.json
    auth_refresh_response.json
    me_response.json
    device_create_response.json
    device_update_response.json
    sync_initial_response.json
    sync_incremental_response.json
    sync_access_revoked_response.json
    push_accepted_response.json
    push_rejected_response.json
    push_conflict_response.json
    workspace_mappings_response.json
    invite_create_response.json
    invite_lookup_response.json
    invite_accept_response.json
    member_remove_response.json
  ].freeze

  test "all contract fixtures parse as JSON" do
    REQUIRED_FIXTURES.each do |filename|
      assert_kind_of Hash, fixture_json(filename), filename
    end
  end

  test "auth fixtures expose user and session shapes" do
    %w[auth_apple_response.json auth_refresh_response.json].each do |filename|
      fixture = fixture_json(filename)
      assert fixture.dig("user", "id").present?, filename
      assert fixture.dig("session", "access_token").present?, filename
      assert fixture.dig("session", "refresh_token").present?, filename
    end
  end

  test "apple auth fixture uses apple subject as the stable identifier" do
    fixture = fixture_json("auth_apple_response.json")

    assert_equal "apple-user-fixture-1", fixture.dig("user", "apple_user_identifier")
    refute_equal fixture.dig("user", "email"), fixture.dig("user", "apple_user_identifier")
  end

  test "sync fixtures use canonical pull envelope" do
    %w[sync_initial_response.json sync_incremental_response.json sync_access_revoked_response.json].each do |filename|
      fixture = fixture_json(filename)
      assert fixture.key?("changes"), filename
      assert fixture.key?("deleted_records"), filename
      assert fixture.key?("next_cursor"), filename
      assert fixture.key?("has_more"), filename
    end
  end

  test "push fixtures cover accepted rejected and conflict states" do
    assert_equal "accepted", fixture_json("push_accepted_response.json").dig("results", 0, "status")
    assert_equal "rejected", fixture_json("push_rejected_response.json").dig("results", 0, "status")
    assert_equal "conflict", fixture_json("push_conflict_response.json").dig("results", 0, "status")
    assert fixture_json("workspace_mappings_response.json").dig("results", 0, "mappings").present?
  end

  test "collaboration fixtures expose invite and member shapes" do
    assert_equal "pending", fixture_json("invite_create_response.json").dig("invite", "status")
    assert_equal "pending", fixture_json("invite_lookup_response.json").dig("invite", "status")
    assert_equal "active", fixture_json("invite_accept_response.json").dig("member", "status")
    assert_equal "removed", fixture_json("member_remove_response.json").dig("member", "status")
  end

  private

  def fixture_json(filename)
    JSON.parse(file_fixture("#{FIXTURE_DIR}/#{filename}").read)
  end
end
