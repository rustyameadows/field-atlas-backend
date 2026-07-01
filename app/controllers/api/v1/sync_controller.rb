module Api
  module V1
    class SyncController < BaseController
      before_action :authenticate_api_session!

      def show
        render json: ::Sync::Pull.new(
          user: current_user,
          cursor: params[:cursor],
          limit: params[:limit],
          scope: params[:scope]
        ).call
      rescue ::Sync::Cursor::InvalidCursor => e
        render_error("invalid_cursor", e.message, status: :unprocessable_entity)
      end
    end
  end
end
