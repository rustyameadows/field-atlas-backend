module Api
  module V1
    class MeController < BaseController
      before_action :authenticate_api_session!

      def show
        render json: {
          user: Serializers.user(current_user),
          device: current_device ? Serializers.device(current_device) : nil
        }
      end
    end
  end
end
