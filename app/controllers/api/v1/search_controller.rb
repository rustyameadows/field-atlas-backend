module Api
  module V1
    class SearchController < BaseController
      def index
        render json: Places::Search.new(search_params).call
      end

      private

      def search_params
        params.permit(:q, :query, :within, :within_place_id, :bbox, :center_lat, :center_lng, :radius_meters, :sources, :types, :limit, :start, :format)
      end
    end
  end
end
