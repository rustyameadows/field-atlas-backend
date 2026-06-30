module Api
  module V1
    class PlaceOptionsController < BaseController
      def show
        render json: {
          kinds: Place::KINDS
        }
      end
    end
  end
end
