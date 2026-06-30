module Api
  module V1
    class PlacesController < BaseController
      PLACE_ATTRIBUTE_KEYS = %i[name slug kind status primary_category metadata coordinate].freeze

      def create
        attributes = place_attributes
        association_rows = external_identifier_rows
        coordinate = coordinate_from_payload(attributes.delete(:coordinate))
        return render json: { errors: coordinate.fetch(:errors) }, status: :unprocessable_content if coordinate.key?(:errors)

        place = nil
        Place.transaction do
          place = Place.new(attributes)
          place.slug = place.name.to_s.parameterize if place.slug.blank?
          place.status = "published" if attributes[:status].blank?
          place.centroid = coordinate.fetch(:point) if coordinate.fetch(:point).present?
          place.save!

          association_rows.each do |row|
            place.external_identifiers.create!(
              provider: row.fetch(:provider),
              identifier: row.fetch(:identifier),
              identifier_kind: row.fetch(:identifier_kind),
              review_status: "verified"
            )
          end
        end

        render json: serialize_place(place), status: :created
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_content
      end

      private

      def place_attributes
        top_level_payload = params.slice(*PLACE_ATTRIBUTE_KEYS)
        payload = top_level_payload.presence || params[:place].presence || {}
        permitted = payload.permit(:name, :slug, :kind, :status, :primary_category, metadata: {}, coordinate: [ :lat, :lng ])
        permitted.to_h.symbolize_keys
      end

      def external_identifier_rows
        Array(raw_external_identifier_payload).flat_map do |raw_association|
          permitted = parameters_for(raw_association).permit(
            :provider,
            :identifier,
            :identifier_kind,
            identifiers: [ :identifier, :identifier_kind ]
          )
          provider = permitted[:provider].to_s.strip.downcase

          if permitted[:identifiers].present?
            Array(permitted[:identifiers]).map do |raw_identifier|
              identifier = parameters_for(raw_identifier).permit(:identifier, :identifier_kind)
              external_identifier_row(provider, identifier[:identifier], identifier[:identifier_kind])
            end
          else
            external_identifier_row(provider, permitted[:identifier], permitted[:identifier_kind])
          end
        end
      end

      def raw_external_identifier_payload
        return params[:associations] if params[:associations].present?
        return params[:external_identifiers] if params[:external_identifiers].present?
        return [ { provider: params[:provider], identifiers: params[:identifiers] } ] if params[:provider].present? || params[:identifiers].present?

        place_payload = params[:place]
        return [] unless place_payload.respond_to?(:[])

        place_payload[:associations].presence || place_payload[:external_identifiers].presence || []
      end

      def external_identifier_row(provider, identifier, identifier_kind)
        {
          provider: provider,
          identifier: identifier.to_s.strip,
          identifier_kind: identifier_kind.presence || "primary"
        }
      end

      def parameters_for(payload)
        return payload if payload.respond_to?(:permit)

        ActionController::Parameters.new(payload || {})
      end

      def coordinate_from_payload(raw_coordinate)
        return { point: nil } if raw_coordinate.blank?

        lat = raw_coordinate[:lat].presence || raw_coordinate["lat"].presence
        lng = raw_coordinate[:lng].presence || raw_coordinate["lng"].presence
        return { errors: [ "coordinate requires lat and lng" ] } if lat.blank? || lng.blank?

        { point: Places::Geo.point(lat: Float(lat), lng: Float(lng)) }
      rescue ArgumentError, TypeError
        { errors: [ "coordinate lat and lng must be numbers" ] }
      end

      def serialize_place(place)
        {
          id: place.id,
          name: place.name,
          slug: place.slug,
          kind: place.kind,
          status: place.status,
          primary_category: place.primary_category,
          coordinate: coordinate_from_point(place.centroid),
          source_ids: place.source_ids_by_provider
        }
      end

      def coordinate_from_point(point)
        return if point.blank?

        { lat: point.y, lng: point.x }
      end
    end
  end
end
