module Api
  module V1
    class DevicesController < BaseController
      before_action :authenticate_api_session!

      def create
        device = ::Devices::Registrar.call(user: current_user, attrs: device_params.to_h)
        current_api_session.update!(device: device) if current_api_session.device_id.blank?
        render json: { device: Serializers.device(device) }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_error("invalid_device", e.record.errors.full_messages.to_sentence.presence || e.message, status: :unprocessable_entity)
      end

      def update
        device = current_user.devices.active.find(params[:id])
        device.assign_attributes(update_device_params)
        device.revision += 1 if device.changed?
        device.last_seen_at = Time.current
        device.save!
        render json: { device: Serializers.device(device) }
      rescue ActiveRecord::RecordInvalid => e
        render_error("invalid_device", e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      private

      def device_params
        params.permit(:device_id, :client_device_id, :name, :platform, :app_version, :build_number, :push_token, :push_environment)
      end

      def update_device_params
        params.permit(:name, :platform, :app_version, :build_number, :push_token, :push_environment)
      end
    end
  end
end
