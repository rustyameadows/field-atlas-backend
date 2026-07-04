require "test_helper"

class FieldAtlasSyncSchemaTest < ActiveSupport::TestCase
  REQUIRED_TABLES = %w[
    users user_auth_identities api_sessions devices trips trip_members
    trip_invites trip_segments trip_stops trip_stop_option_links
    route_snapshots route_snapshot_stops route_legs route_steps
    favorite_places place_lists place_list_items search_history_entries
    search_sessions search_result_snapshots user_settings memory_assets
    drive_sessions assets asset_links client_operations sync_events deleted_records
  ].freeze

  test "sync tables exist" do
    missing = REQUIRED_TABLES.reject { |table| ActiveRecord::Base.connection.data_source_exists?(table) }
    assert_empty missing
  end

  test "trip stop kinds normalize current and legacy values" do
    assert_equal "idea", TripStop.normalize_kind("open_idea")
    assert_equal "waypoint", TripStop.normalize_kind("route_waypoint")
    assert_equal "route_stop", TripStop.normalize_kind("route_stop")
  end
end
