module Sources
  module Nps
    class ChildPlacePromotion
      class MissingParentPark < StandardError; end

      CHILD_RECORD_TYPES = %w[campground visitor_center].freeze

      def initialize(source_record)
        @source_record = source_record
      end

      def call
        raise ArgumentError, "Only NPS child records can be promoted" unless source_record.provider == "nps" && CHILD_RECORD_TYPES.include?(source_record.record_type)
        raise MissingParentPark, "Missing parent NPS park: #{park_code}" if containing_place.blank?

        Place.transaction do
          place = existing_place || Place.new
          place.assign_attributes(place_attributes(place))
          place.save!

          link = PlaceSourceLink.find_or_initialize_by(place: place, source_record: source_record)
          link.assign_attributes(match_type: "source_id", confidence: 1, review_status: "verified")
          link.save!

          containment = PlaceContainment.find_or_initialize_by(containing_place: containing_place, source_record: source_record)
          containment.assign_attributes(relationship_type: "contains", confidence: 1, review_status: "verified")
          containment.save!

          place
        end
      end

      private

      attr_reader :source_record

      def existing_place
        source_record.places.joins(:place_source_links).where(place_source_links: { review_status: %w[auto verified] }).first
      end

      def place_attributes(place)
        {
          name: source_record.name,
          slug: slug_for(place),
          kind: kind,
          status: "published",
          primary_category: primary_category,
          centroid: source_record.centroid,
          geometry: source_record.geometry,
          metadata: place.metadata.presence || {}
        }
      end

      def slug_for(place)
        return place.slug if place.slug.present?

        base = source_record.name.parameterize
        return base unless Place.where.not(id: place.id).exists?(slug: base)

        "#{base}-nps-#{source_record.source_id.parameterize}"
      end

      def kind
        source_record.record_type == "campground" ? "campground" : "poi"
      end

      def primary_category
        source_record.record_type
      end

      def containing_place
        @containing_place ||= ParkUnit.find_by(agency: "nps", official_code: park_code)&.place
      end

      def park_code
        source_record.normalized_payload["park_code"].presence
      end
    end
  end
end
