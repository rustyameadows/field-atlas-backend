module Api
  module V1
    class SyncOperationsController < BaseController
      before_action :authenticate_api_session!

      def create
        operations = Array(params[:operations]).map do |operation|
          operation.respond_to?(:to_unsafe_h) ? operation.to_unsafe_h : operation
        end

        render json: ::Sync::OperationProcessor.new(
          user: current_user,
          device: current_device,
          operations: operations
        ).call
      end
    end
  end
end
