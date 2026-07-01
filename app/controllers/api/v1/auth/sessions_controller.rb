module Api
  module V1
    module Auth
      class SessionsController < BaseController
        before_action :authenticate_api_session!

        def destroy
          current_api_session.revoke!
          head :no_content
        end
      end
    end
  end
end
