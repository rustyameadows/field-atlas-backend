module Auth
  class AppleIdentityVerifier
    class VerificationError < StandardError; end

    ISSUER = "https://appleid.apple.com"
    DEFAULT_AUDIENCE = ENV.fetch("APPLE_AUTH_AUDIENCE", "com.rustymeadows.DestinationApp")

    def initialize(audience: DEFAULT_AUDIENCE)
      @audience = audience
    end

    def verify(identity_token:, email: nil, full_name: nil)
      raise VerificationError, "identity_token is required" if identity_token.blank?

      return fake_claims(identity_token, email, full_name) if Rails.env.local? || Rails.env.test?

      verify_with_jwt!(identity_token)
    end

    private

    def fake_claims(identity_token, email, full_name)
      {
        "iss" => ISSUER,
        "aud" => @audience,
        "sub" => email.presence || identity_token,
        "email" => email,
        "email_verified" => email.present?,
        "name" => full_name,
        "exp" => 1.hour.from_now.to_i
      }
    end

    def verify_with_jwt!(identity_token)
      require "jwt"

      jwks = Rails.cache.fetch("apple_identity_jwks", expires_in: 12.hours) do
        response = Net::HTTP.get(URI("https://appleid.apple.com/auth/keys"))
        JSON.parse(response)
      end

      payload, = JWT.decode(
        identity_token,
        nil,
        true,
        algorithms: [ "RS256" ],
        iss: ISSUER,
        verify_iss: true,
        aud: @audience,
        verify_aud: true,
        jwks: jwks
      )
      payload
    rescue LoadError
      raise VerificationError, "jwt gem is required for production Apple auth verification"
    rescue JWT::DecodeError, JSON::ParserError, Errno::ECONNREFUSED, SocketError => e
      raise VerificationError, e.message
    end
  end
end
