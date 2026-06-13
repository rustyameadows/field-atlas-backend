require "test_helper"

class Sources::Nps::NormalizerTest < ActiveSupport::TestCase
  test "normalizes park records into source record attributes and search candidates" do
    payload = json_fixture("nps/parks_pinnacles.json").fetch("data").first
    normalized = Sources::Nps::Normalizer.new(record_type: "park", payload: payload).call

    assert_equal "nps", normalized.provider
    assert_equal "park", normalized.record_type
    assert_equal "pinn", normalized.source_id
    assert_equal "Pinnacles National Park", normalized.name
    assert_equal "park_unit", normalized.category
    assert_equal({ lat: 36.49029208, lng: -121.1813607 }, normalized.coordinate)
    assert_equal "source:nps:park:pinn", normalized.result_id
  end

  test "normalizes NPS place titles and inconsistent coordinate shapes" do
    payload = json_fixture("nps/places_pinnacles.json").fetch("data").first
    normalized = Sources::Nps::Normalizer.new(record_type: "place", payload: payload).call

    assert_equal "145046F9-F0B4-45AB-A422-6DB1D9F876D0", normalized.source_id
    assert_equal "Bear Gulch Reservoir", normalized.name
    assert_equal "nps_place", normalized.category
    assert_equal({ lat: 36.472883116471955, lng: -121.187524845061 }, normalized.coordinate)
  end
end
