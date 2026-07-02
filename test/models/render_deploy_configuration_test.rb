require "test_helper"

class RenderDeployConfigurationTest < ActiveSupport::TestCase
  SOLID_TABLES = %w[
    solid_cache_entries
    solid_queue_jobs
    solid_cable_messages
  ].freeze

  test "production uses one primary database configuration" do
    configs = ActiveRecord::Base.configurations.configs_for(env_name: "production")

    assert_equal [ "primary" ], configs.map(&:name)
  end

  test "solid backing tables live in the primary schema" do
    missing = SOLID_TABLES.reject { |table| ActiveRecord::Base.connection.data_source_exists?(table) }

    assert_empty missing
  end
end
