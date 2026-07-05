module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_api_session!

      def show
        user = User.active.includes(:profile_photo_asset).find(params[:id])
        render json: { user: Serializers.public_user(user) }
      end
    end
  end
end
