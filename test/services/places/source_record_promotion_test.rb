require "test_helper"

class Places::SourceRecordPromotionTest < ActiveSupport::TestCase
  test "promotes NPS park source records into canonical places idempotently" do
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
        "subtitle" => "National Park Service - National Park",
        "designation" => "National Park",
        "states" => "CA"
      },
      fetched_at: 1.hour.ago
    )

    2.times { Places::SourceRecordPromotion.new(source_record).call }

    assert_equal 1, Place.count
    place = Place.first
    assert_equal "Pinnacles National Park", place.name
    assert_equal "pinnacles-national-park", place.slug
    assert_equal "park_unit", place.kind
    assert_equal "published", place.status
    assert_equal "national_park", place.primary_category
    assert_equal({ "provider_codes" => { "nps" => "pinn" } }, place.metadata)

    assert_equal 1, ParkUnit.count
    assert_equal "nps", place.park_unit.agency
    assert_equal "National Park", place.park_unit.designation
    assert_equal [ "CA" ], place.park_unit.states
    assert_equal "pinn", place.park_unit.official_code
    assert_equal "nps", place.park_unit.source_provider

    assert_equal 1, PlaceSourceLink.count
    link = PlaceSourceLink.first
    assert_equal place, link.place
    assert_equal source_record, link.source_record
    assert_equal "source_id", link.match_type
    assert_equal "verified", link.review_status
    assert_equal 1.0, link.confidence
  end
end
