module Sources
  module Nps
    NormalizedRecord = Data.define(
      :provider,
      :record_type,
      :source_id,
      :name,
      :category,
      :subtitle,
      :coordinate,
      :raw_payload,
      :normalized_payload,
      :source_url,
      :relevance_score
    ) do
      def result_id
        "source:#{provider}:#{record_type}:#{source_id}"
      end

      def to_search_result(freshness: "live_query", fetched_at: Time.current)
        {
          id: result_id,
          result_type: "source_record",
          canonical_place_id: nil,
          source: provider,
          source_id: source_id,
          name: name,
          subtitle: subtitle,
          category: category,
          geometry_type: coordinate.present? ? "point" : nil,
          coordinate: coordinate,
          source_freshness: {
            mode: freshness,
            fetched_at: fetched_at.iso8601
          }
        }.compact
      end
    end
  end
end
