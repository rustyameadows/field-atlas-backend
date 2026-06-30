module Places
  class SourceRecordUpsert
    def initialize(dataset:)
      @dataset = dataset
    end

    def call(normalized)
      record = SourceRecord.find_or_initialize_by(
        provider: normalized.provider,
        record_type: normalized.record_type,
        source_id: normalized.source_id
      )
      coordinate = normalized.coordinate
      point = Places::Geo.point(lng: coordinate.fetch(:lng), lat: coordinate.fetch(:lat)) if coordinate.present?

      record.assign_attributes(
        source_dataset: dataset,
        name: normalized.name,
        raw_payload: normalized.raw_payload,
        normalized_payload: normalized.normalized_payload,
        centroid: point,
        geometry: point,
        fetched_at: Time.current,
        expires_at: 1.day.from_now
      )
      record.save!
      record
    end

    private

    attr_reader :dataset
  end
end
