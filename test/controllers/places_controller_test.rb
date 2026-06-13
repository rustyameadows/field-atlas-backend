require "test_helper"

class PlacesControllerTest < ActionDispatch::IntegrationTest
  test "dashboard renders search surface and stored source records" do
    dataset = SourceDataset.create!(provider: "nps", name: "National Park Service", freshness_mode: "live_query", status: "active")
    SourceRecord.create!(
      source_dataset: dataset,
      provider: "nps",
      record_type: "park",
      source_id: "pinn",
      name: "Pinnacles National Park",
      raw_payload: json_fixture("nps/parks_pinnacles.json").fetch("data").first,
      normalized_payload: {
        "category" => "park_unit",
        "coordinate" => { "lat" => 36.49029208, "lng" => -121.1813607 },
        "subtitle" => "National Park Service"
      },
      fetched_at: 1.hour.ago
    )

    get root_path, params: { q: "pinnacles", sources: "nps", types: "park_unit", limit: 10 }

    assert_response :success
    assert_select "h1", "Places Pipeline"
    assert_select "a", text: "API JSON"
    assert_select "td strong", text: "Pinnacles National Park", count: 2
    assert_select "code", text: %r{/api/v1/search}
  end
end
