module Api
  module V1
    class PlaceExternalIdentifiersController < BaseController
      def create
        place = Place.find_by(id: params[:place_id])
        return render json: { error: "Place not found" }, status: :not_found if place.blank?

        provider = params[:provider].to_s.strip.downcase
        rows = identifier_rows
        errors = validation_errors(provider, rows)
        return render json: { errors: errors }, status: :unprocessable_content if errors.any?

        PlaceExternalIdentifier.transaction do
          rows.uniq { |row| row.fetch(:identifier) }.each do |row|
            record = PlaceExternalIdentifier.find_or_initialize_by(
              provider: provider,
              identifier: row.fetch(:identifier)
            )
            record.assign_attributes(
              place: place,
              identifier_kind: row.fetch(:identifier_kind),
              review_status: "verified"
            )
            record.save!
          end
        end

        render json: {
          place_id: place.id,
          source_ids: place.reload.source_ids_by_provider
        }
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_content
      end

      private

      def identifier_rows
        Array(params[:identifiers]).map do |raw_identifier|
          permitted = if raw_identifier.respond_to?(:permit)
            raw_identifier.permit(:identifier, :identifier_kind)
          else
            ActionController::Parameters.new(raw_identifier).permit(:identifier, :identifier_kind)
          end
          {
            identifier: permitted[:identifier].to_s.strip,
            identifier_kind: permitted[:identifier_kind].presence || "primary"
          }
        end
      end

      def validation_errors(provider, rows)
        errors = []
        errors << "provider can't be blank" if provider.blank?
        errors << "identifiers can't be blank" if rows.blank?

        rows.each do |row|
          identifier = row.fetch(:identifier)
          if identifier.blank?
            errors << "identifier can't be blank"
            next
          end

          existing = PlaceExternalIdentifier.find_by(provider: provider, identifier: identifier)
          next if existing.blank? || existing.place_id.to_s == params[:place_id].to_s

          errors << "#{provider} identifier #{identifier} already belongs to place #{existing.place_id}"
        end

        errors.uniq
      end
    end
  end
end
