module Api
  module V1
    class BaseController < ActionController::API
      class AuthenticationError < StandardError; end
      class ForbiddenError < StandardError; end

      rescue_from ForbiddenError do |error|
        render_error("forbidden", error.message.presence || "You do not have permission to perform this action.", status: :forbidden)
      end

      rescue_from AuthenticationError do
        render_error("unauthorized", "Authentication is required.", status: :unauthorized)
      end

      rescue_from ActiveRecord::RecordNotFound do
        render_error("not_found", "The requested record was not found.", status: :not_found)
      end

      private

      attr_reader :current_api_session

      def authenticate_api_session!
        token = bearer_token
        raise AuthenticationError if token.blank?

        digest = ::Auth::TokenDigest.digest(token)
        @current_api_session = ApiSession.not_revoked.find_by(access_token_digest: digest)
        raise AuthenticationError if @current_api_session.blank? || !@current_api_session.access_active?

        @current_api_session.update!(last_used_at: Time.current)
        current_device&.mark_seen!
      end

      def current_user
        current_api_session&.user
      end

      def current_device
        current_api_session&.device
      end

      def require_admin_user!
        raise ForbiddenError unless current_user&.admin?
      end

      def bearer_token
        header = request.authorization.to_s
        return unless header.start_with?("Bearer ")

        header.delete_prefix("Bearer ").presence
      end

      def render_error(code, message, status:, details: [])
        render json: {
          error: {
            code: code,
            message: message,
            details: Array(details)
          }
        }, status: status
      end
    end
  end
end
