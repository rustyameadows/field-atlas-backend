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
    assert_select "td", text: "Pinnacles National Park", minimum: 2
    assert_includes response.body, "/api/v1/search"
  end

  test "dashboard renders canonical places with external associations" do
    place = Place.create!(
      name: "Joshua Tree National Park",
      slug: "joshua-tree-national-park",
      kind: "park_unit",
      status: "published",
      primary_category: "national_park"
    )
    PlaceExternalIdentifier.create!(place: place, provider: "mapkit", identifier: "mapkit-jotr")
    PlaceExternalIdentifier.create!(place: place, provider: "nps", identifier: "jotr")

    get root_path

    assert_response :success
    assert_select "h2", "Canonical Places"
    assert_select "td", text: "Joshua Tree National Park"
    assert_select "td", text: "park_unit"
    assert_select "td", text: "published"
    assert_select "td", text: /mapkit: mapkit-jotr/
    assert_select "td", text: /nps: jotr/
  end
end
