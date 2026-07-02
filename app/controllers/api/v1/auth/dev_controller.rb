module Api
  module V1
    module Auth
      class DevController < AppleController
        def create
          return render_error("not_found", "Not found.", status: :not_found) unless Rails.env.development? || Rails.env.test?

          email = params[:email].presence || "local-dev@example.com"
          full_name = params[:full_name].presence || params[:name].presence || "Local Developer"
          claims = {
            "iss" => ::Auth::AppleIdentityVerifier::DEFAULT_ISSUER,
            "aud" => ::Auth::AppleIdentityVerifier::DEFAULT_AUDIENCE,
            "sub" => params[:apple_user_identifier].presence || email,
            "email" => email,
            "email_verified" => true,
            "name" => full_name,
            "exp" => 1.hour.from_now.to_i
          }

          user, device = upsert_user_and_device(claims)
          api_session, access_token, refresh_token = ::Auth::SessionIssuer.issue(user: user, device: device)

          render json: Serializers.auth(
            user: user,
            api_session: api_session,
            access_token: access_token,
            refresh_token: refresh_token,
            device: device
          ), status: :created
        end
      end
    end
  end
end
