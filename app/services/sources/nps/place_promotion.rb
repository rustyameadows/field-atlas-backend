module Sources
  module Nps
    class PlacePromotion
      def initialize(source_record)
        @source_record = source_record
      end

      def call
        raise ArgumentError, "Only NPS park records can be promoted" unless source_record.record_type == "park"

        Place.transaction do
          place = existing_place || Place.new
          place.assign_attributes(place_attributes)
          place.save!

          park_unit = place.park_unit || place.build_park_unit
          park_unit.assign_attributes(park_unit_attributes)
          park_unit.save!

          link = PlaceSourceLink.find_or_initialize_by(place: place, source_record: source_record)
          link.assign_attributes(match_type: "source_id", confidence: 1, review_status: "verified")
          link.save!

          place
        end
      end

      private

      attr_reader :source_record

      def existing_place
        linked_place || coded_place
      end

      def linked_place
        source_record.places.joins(:place_source_links).where(place_source_links: { review_status: %w[auto verified] }).first
      end

      def coded_place
        ParkUnit.find_by(agency: "nps", official_code: source_record.source_id)&.place
      end

      def place_attributes
        {
          name: source_record.name,
          slug: slug,
          kind: "park_unit",
          status: "published",
          primary_category: "park_unit",
          centroid: source_record.centroid,
          geometry: source_record.geometry,
          metadata: metadata
        }
      end

      def slug
        return existing_place.slug if existing_place&.slug.present?

        base = source_record.name.parameterize
        return base unless Place.exists?(slug: base)

        "#{base}-nps-#{source_record.source_id}"
      end

      def metadata
        (existing_place&.metadata || {}).deep_dup.tap do |payload|
          payload["provider_codes"] = (payload["provider_codes"] || {}).merge("nps" => source_record.source_id)
        end
      end

      def park_unit_attributes
        {
          agency: "nps",
          designation: source_record.normalized_payload["designation"],
          states: states,
          official_code: source_record.source_id,
          source_provider: "nps"
        }
      end

      def states
        value = source_record.normalized_payload["states"]
        case value
        when Array
          value
        else
          value.to_s.split(",").map(&:strip).reject(&:blank?)
        end
      end
    end
  end
end
