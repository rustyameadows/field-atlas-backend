require "test_helper"

class SearchApiTest < ActionDispatch::IntegrationTest
  test "search returns live NPS candidates and persists source records" do
    stub_nps("/parks", "q" => "pinnacles", "limit" => "10", "sort" => "-relevanceScore").
      to_return(status: 200, body: file_fixture("nps/parks_pinnacles.json").read, headers: json_headers)
    stub_nps("/places", "q" => "pinnacles", "limit" => "10").
      to_return(status: 200, body: file_fixture("nps/places_pinnacles.json").read, headers: json_headers)
    stub_nps("/campgrounds", "q" => "pinnacles", "limit" => "10").
      to_return(status: 200, body: file_fixture("nps/campgrounds_pinnacles.json").read, headers: json_headers)
    stub_nps("/visitorcenters", "q" => "pinnacles", "limit" => "10").
      to_return(status: 200, body: file_fixture("nps/visitorcenters_pinnacles.json").read, headers: json_headers)

    with_nps_key do
      get "/api/v1/search", params: { q: "pinnacles", sources: "nps", limit: 10 }
    end

    assert_response :success
    body = ::JSON.parse(response.body)
    assert_equal false, body.fetch("partial")
    assert_equal "ok", body.fetch("source_statuses").find { |status| status.fetch("source") == "nps" }.fetch("status")
    assert_equal [
      "Pinnacles National Park",
      "Bear Gulch Reservoir",
      "Pinnacles Campground",
      "Bear Gulch Nature Center"
    ], body.fetch("results").map { |result| result.fetch("name") }
    assert_equal 4, SourceRecord.where(provider: "nps").count
  end

  test "blank map search uses stored records and does not call NPS live" do
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

    get "/api/v1/search", params: {
      sources: "nps",
      bbox: "-122.0,36.0,-121.0,37.0"
    }

    assert_response :success
    body = ::JSON.parse(response.body)
    assert_equal [ "Pinnacles National Park" ], body.fetch("results").map { |result| result.fetch("name") }
    assert_not_requested :get, %r{\Ahttps://developer\.nps\.gov/api/v1/}
  end

  test "NPS failure returns partial response with stored records" do
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
    stub_nps("/parks", "q" => "pinnacles", "limit" => "10", "sort" => "-relevanceScore").
      to_return(status: 500, body: { error: "failed" }.to_json, headers: json_headers)

    with_nps_key do
      get "/api/v1/search", params: { q: "pinnacles", sources: "nps", types: "park_unit", limit: 10 }
    end

    assert_response :success
    body = ::JSON.parse(response.body)
    assert_equal true, body.fetch("partial")
    assert_equal "failed", body.fetch("source_statuses").find { |status| status.fetch("source") == "nps" }.fetch("status")
    assert_equal [ "Pinnacles National Park" ], body.fetch("results").map { |result| result.fetch("name") }
  end

  test "NPS rate limit returns partial response with endpoint status" do
    stub_nps("/parks", "q" => "pinnacles", "limit" => "10", "sort" => "-relevanceScore").
      to_return(status: 429, body: { error: "rate limit" }.to_json, headers: json_headers.merge("x-ratelimit-remaining" => "0"))

    with_nps_key do
      get "/api/v1/search", params: { q: "pinnacles", sources: "nps", types: "park_unit", limit: 10 }
    end

    assert_response :success
    body = ::JSON.parse(response.body)
    nps_status = body.fetch("source_statuses").find { |status| status.fetch("source") == "nps" }

    assert_equal true, body.fetch("partial")
    assert_equal "failed", nps_status.fetch("status")
    assert_equal "failed", nps_status.fetch("endpoints").fetch("/parks").fetch("status")
    assert_equal 429, nps_status.fetch("endpoints").fetch("/parks").fetch("http_status")
    assert_empty body.fetch("results")
  end

  test "linked source records are deduped behind canonical places" do
    place = Place.create!(
      name: "Pinnacles National Park",
      slug: "pinnacles-national-park",
      kind: "park_unit",
      status: "published",
      primary_category: "national_park"
    )
    dataset = SourceDataset.create!(provider: "nps", name: "National Park Service", freshness_mode: "live_query", status: "active")
    source_record = SourceRecord.create!(
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
    PlaceSourceLink.create!(
      place: place,
      source_record: source_record,
      match_type: "source_id",
      confidence: 1,
      review_status: "verified"
    )

    get "/api/v1/search", params: { q: "pinnacles", sources: "field_atlas,nps", limit: 10 }

    assert_response :success
    body = ::JSON.parse(response.body)

    assert_equal [ "canonical_place" ], body.fetch("results").map { |result| result.fetch("result_type") }
    assert_equal [ "Pinnacles National Park" ], body.fetch("results").map { |result| result.fetch("name") }
  end

  test "missing NPS key degrades source without failing whole search" do
    get "/api/v1/search", params: { q: "pinnacles", sources: "nps", limit: 10 }

    assert_response :success
    body = ::JSON.parse(response.body)
    assert_equal true, body.fetch("partial")
    assert_equal "missing_key", body.fetch("source_statuses").find { |status| status.fetch("source") == "nps" }.fetch("status")
    assert_empty body.fetch("results")
  end

  private

  def stub_nps(path, query)
    stub_request(:get, "https://developer.nps.gov/api/v1#{path}").
      with(query: query, headers: { "X-Api-Key" => "test-nps-key" })
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  def with_nps_key
    old_key = ENV["NPS_API_KEY"]
    ENV["NPS_API_KEY"] = "test-nps-key"
    yield
  ensure
    ENV["NPS_API_KEY"] = old_key
  end
end
