module Api
  module V1
    module Auth
      class AppleController < BaseController
        def create
          claims = ::Auth::AppleIdentityVerifier.new.verify(
            identity_token: params[:identity_token],
            nonce: params[:nonce],
            email: params[:email],
            full_name: params[:full_name]
          )

          user, device = upsert_user_and_device(claims)
          api_session, access_token, refresh_token = ::Auth::SessionIssuer.issue(user: user, device: device)

          render json: Serializers.auth(
            user: user,
            api_session: api_session,
            access_token: access_token,
            refresh_token: refresh_token,
            device: device
          ), status: :created
        rescue ::Auth::AppleIdentityVerifier::VerificationError => e
          render_error("invalid_apple_identity", e.message, status: :unauthorized)
        end

        protected

        def upsert_user_and_device(claims)
          identity = UserAuthIdentity.find_or_initialize_by(provider: "apple", provider_subject: claims.fetch("sub"))
          user = identity.user || User.new
          provider_display_name = params[:full_name].presence || claims["name"].presence
          user.display_name = provider_display_name if user.display_name.blank? && provider_display_name.present?
          user.email = params[:email].presence || claims["email"].presence || user.email
          user.email_verified = ActiveModel::Type::Boolean.new.cast(claims["email_verified"]) if claims.key?("email_verified")
          user.status ||= "active"

          User.transaction do
            user.save!
            identity.user = user
            identity.email = user.email
            identity.email_verified = user.email_verified
            identity.display_name = provider_display_name.presence || identity.display_name
            identity.raw_claims = claims
            identity.last_verified_at = Time.current
            identity.save!
          end

          [ user, optional_device_for(user) ]
        end

        def optional_device_for(user)
          return if params[:device_id].blank?

          ::Devices::Registrar.call(user: user, attrs: {
            device_id: params[:device_id],
            name: params[:device_name].presence || params[:name],
            platform: params[:platform] || "ios",
            app_version: params[:app_version],
            build_number: params[:build_number]
          })
        end
      end
    end
  end
end
