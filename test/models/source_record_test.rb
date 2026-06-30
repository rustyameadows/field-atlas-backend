require "test_helper"

class SourceRecordTest < ActiveSupport::TestCase
  test "normalizes names and tracks payload hash changes" do
    dataset = SourceDataset.create!(
      provider: "nps",
      name: "National Park Service",
      freshness_mode: "live_query",
      status: "active"
    )

    record = SourceRecord.create!(
      source_dataset: dataset,
      provider: "nps",
      record_type: "park",
      source_id: "pinn",
      name: "Pinnacles National Park",
      raw_payload: { "parkCode" => "pinn", "fullName" => "Pinnacles National Park" },
      fetched_at: Time.current
    )

    assert_equal "pinnacles national park", record.normalized_name
    original_hash = record.payload_hash

    record.update!(raw_payload: record.raw_payload.merge("designation" => "National Park"))

    assert_not_equal original_hash, record.payload_hash
  end

  test "enforces provider record identity" do
    dataset = SourceDataset.create!(
      provider: "nps",
      name: "National Park Service",
      freshness_mode: "live_query",
      status: "active"
    )

    SourceRecord.create!(
      source_dataset: dataset,
      provider: "nps",
      record_type: "park",
      source_id: "pinn",
      name: "Pinnacles National Park",
      raw_payload: { "parkCode" => "pinn" },
      fetched_at: Time.current
    )

    duplicate = SourceRecord.new(
      source_dataset: dataset,
      provider: "nps",
      record_type: "park",
      source_id: "pinn",
      name: "Pinnacles",
      raw_payload: { "parkCode" => "pinn" },
      fetched_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:source_id], "has already been taken"
  end
end
