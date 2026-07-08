require "test_helper"

class TripInviteUrlTest < ActiveSupport::TestCase
  test "builds public web invite URL with encoded token" do
    with_field_atlas_web_base_url("https://field-atlas.com/") do
      assert_equal "https://field-atlas.com/invites/?token=abc%2B123%2F%3F", TripInviteUrl.for("abc+123/?")
    end
  end

  test "requires web base URL in production" do
    with_field_atlas_web_base_url(nil) do
      with_production_rails_env do
        assert_raises(KeyError) { TripInviteUrl.for("invite-token") }
      end
    end
  end

  private

  def with_field_atlas_web_base_url(value)
    original_value = ENV["FIELD_ATLAS_WEB_BASE_URL"]
    value.nil? ? ENV.delete("FIELD_ATLAS_WEB_BASE_URL") : ENV["FIELD_ATLAS_WEB_BASE_URL"] = value
    yield
  ensure
    original_value.nil? ? ENV.delete("FIELD_ATLAS_WEB_BASE_URL") : ENV["FIELD_ATLAS_WEB_BASE_URL"] = original_value
  end

  def with_production_rails_env
    original_production_predicate = Rails.env.method(:production?)
    Rails.env.define_singleton_method(:production?) { true }
    yield
  ensure
    Rails.env.define_singleton_method(:production?) { original_production_predicate.call }
  end
end
