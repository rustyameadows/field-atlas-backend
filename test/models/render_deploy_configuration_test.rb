require "test_helper"
require "erb"
require "yaml"

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

  test "render solid queue threads fit the primary database pool" do
    env_vars = render_env_vars
    pool_size = env_vars.fetch("RAILS_MAX_THREADS").fetch("value").to_i
    worker_threads = queue_worker_threads(env_vars).max || 1
    estimated_solid_queue_threads = worker_threads + 2

    assert_equal "1", env_vars.fetch("SOLID_QUEUE_WORKER_THREADS").fetch("value")
    assert_operator estimated_solid_queue_threads, :<=, pool_size,
      "Solid Queue reserves worker threads plus worker and heartbeat threads"
  end

  private

  def render_web_service
    render_config.fetch("services").find { |service| service.fetch("type") == "web" }
  end

  def render_config
    YAML.safe_load(Rails.root.join("render.yaml").read, aliases: true)
  end

  def render_env_vars
    render_web_service.fetch("envVars").index_by { |var| var.fetch("key") }
  end

  def queue_worker_threads(env_vars)
    queue_config(env_vars).fetch("production").fetch("workers").map { |worker| worker.fetch("threads").to_i }
  end

  def queue_config(env_vars)
    rendered_queue_config = with_render_env(env_vars) do
      ERB.new(Rails.root.join("config/queue.yml").read).result
    end

    YAML.safe_load(rendered_queue_config, aliases: true)
  end

  def with_render_env(env_vars)
    values = env_vars.filter_map do |key, env_var|
      value = env_var["value"]
      [ key, value ] if value
    end.to_h
    original_values = values.transform_values { nil }
    values.each_key { |key| original_values[key] = ENV[key] }
    values.each { |key, value| ENV[key] = value }

    yield
  ensure
    original_values&.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
