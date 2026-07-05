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

      def update
        current_user.assign_attributes(profile_params)

        if current_user.changed?
          current_user.revision += 1
          current_user.save!
          Sync::EventRecorder.record!(
            current_user,
            action: "updated",
            actor_user: current_user,
            actor_device: current_device,
            user: current_user
          )
        else
          current_user.save!
        end

        render json: { user: Serializers.user(current_user) }
      rescue ActiveRecord::RecordInvalid => e
        render_error("validation_failed", e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      private

      def profile_params
        params.require(:user).permit(:display_name, :username, :bio, :profile_photo_asset_id)
      end
    end
  end
end
