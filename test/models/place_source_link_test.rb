require "test_helper"

class PlaceSourceLinkTest < ActiveSupport::TestCase
  test "allows one canonical place to link to multiple provider records" do
    place = create_place
    first_record = create_source_record(source_id: "pinn", record_type: "park", name: "Pinnacles National Park")
    second_record = create_source_record(source_id: "bear-gulch", record_type: "place", name: "Bear Gulch Reservoir")

    PlaceSourceLink.create!(
      place: place,
      source_record: first_record,
      match_type: "source_id",
      confidence: 1,
      review_status: "verified"
    )

    second_link = PlaceSourceLink.new(
      place: place,
      source_record: second_record,
      match_type: "name_geometry",
      confidence: 0.8,
      review_status: "auto"
    )

    assert second_link.valid?
  end

  test "does not allow duplicate links for the same place and source record" do
    place = create_place
    source_record = create_source_record(source_id: "pinn", record_type: "park", name: "Pinnacles National Park")

    PlaceSourceLink.create!(
      place: place,
      source_record: source_record,
      match_type: "source_id",
      confidence: 1,
      review_status: "verified"
    )

    duplicate = PlaceSourceLink.new(
      place: place,
      source_record: source_record,
      match_type: "manual",
      confidence: 0.5,
      review_status: "auto"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:source_record_id], "has already been taken"
  end

  private

  def create_place
    Place.create!(
      name: "Pinnacles National Park",
      slug: "pinnacles-national-park",
      kind: "park_unit",
      status: "published",
      primary_category: "national_park"
    )
  end

  def create_source_record(source_id:, record_type:, name:)
    dataset = SourceDataset.find_or_create_by!(
      provider: "nps",
      name: "National Park Service"
    ) do |source_dataset|
      source_dataset.freshness_mode = "live_query"
      source_dataset.status = "active"
    end

    SourceRecord.create!(
      source_dataset: dataset,
      provider: "nps",
      record_type: record_type,
      source_id: source_id,
      name: name,
      raw_payload: { "id" => source_id, "name" => name },
      fetched_at: Time.current
    )
  end
end
