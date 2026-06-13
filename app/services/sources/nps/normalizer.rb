module Sources
  module Nps
    class Normalizer
      PROVIDER = "nps"

      CATEGORY_BY_RECORD_TYPE = {
        "park" => "park_unit",
        "place" => "nps_place",
        "campground" => "campground",
        "visitor_center" => "visitor_center"
      }.freeze

      def initialize(record_type:, payload:)
        @record_type = record_type
        @payload = payload
      end

      def call
        NormalizedRecord.new(
          provider: PROVIDER,
          record_type: record_type,
          source_id: source_id,
          name: name,
          category: CATEGORY_BY_RECORD_TYPE.fetch(record_type),
          subtitle: subtitle,
          coordinate: coordinate,
          raw_payload: payload,
          normalized_payload: normalized_payload,
          source_url: payload["url"],
          relevance_score: payload["relevanceScore"].to_f
        )
      end

      private

      attr_reader :record_type, :payload

      def source_id
        record_type == "park" ? payload.fetch("parkCode") : payload.fetch("id")
      end

      def name
        payload["fullName"].presence || payload["title"].presence || payload.fetch("name")
      end

      def subtitle
        case record_type
        when "park"
          [ "National Park Service", payload["designation"] ].compact_blank.join(" - ")
        else
          "National Park Service"
        end
      end

      def coordinate
        lat = payload["latitude"].presence&.to_f
        lng = payload["longitude"].presence&.to_f
        return { lat: lat, lng: lng } if lat && lng

        lat_long = payload["latLong"].to_s
        numbers = lat_long.scan(/-?\d+(?:\.\d+)?/).map(&:to_f)
        return if numbers.length < 2

        { lat: numbers[0], lng: numbers[1] }
      end

      def normalized_payload
        {
          "category" => CATEGORY_BY_RECORD_TYPE.fetch(record_type),
          "subtitle" => subtitle,
          "coordinate" => coordinate,
          "source_url" => payload["url"],
          "park_code" => payload["parkCode"] || payload.dig("relatedParks", 0, "parkCode"),
          "designation" => payload["designation"],
          "states" => payload["states"] || payload.dig("relatedParks", 0, "states"),
          "description" => payload["description"] || payload["listingDescription"],
          "images" => payload["images"],
          "relevance_score" => payload["relevanceScore"]
        }.compact
      end
    end
  end
end
