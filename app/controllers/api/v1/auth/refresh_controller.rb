module Api
  module V1
    module Auth
      class RefreshController < BaseController
        def create
          refresh_token = params[:refresh_token].to_s
          api_session = ApiSession.not_revoked.find_by(refresh_token_digest: ::Auth::TokenDigest.digest(refresh_token))

          if api_session.blank? || !api_session.refresh_active?
            return render_error("invalid_refresh_token", "Refresh token is invalid or expired.", status: :unauthorized)
          end

          api_session, access_token, next_refresh_token = ::Auth::SessionIssuer.refresh!(api_session)
          render json: Serializers.auth(
            user: api_session.user,
            api_session: api_session,
            access_token: access_token,
            refresh_token: next_refresh_token
          )
        end
      end
    end
  end
end
