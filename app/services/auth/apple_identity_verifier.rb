module Auth
  class AppleIdentityVerifier
    class VerificationError < StandardError; end

    DEFAULT_AUDIENCE = "com.rustymeadows.DestinationApp"
    DEFAULT_ISSUER = "https://appleid.apple.com"
    DEFAULT_JWKS_URL = "https://appleid.apple.com/auth/keys"
    JWKS_CACHE_TTL = 12.hours

    def initialize(audience: nil, issuer: nil, jwks_url: nil, allow_fake_tokens: Rails.env.local? || Rails.env.test?)
      @audience = audience.presence || ENV["APPLE_CLIENT_ID"].presence || ENV["APPLE_AUTH_AUDIENCE"].presence || DEFAULT_AUDIENCE
      @issuer = issuer.presence || ENV["APPLE_ISSUER"].presence || DEFAULT_ISSUER
      @jwks_url = jwks_url.presence || ENV["APPLE_JWKS_URL"].presence || DEFAULT_JWKS_URL
      @allow_fake_tokens = allow_fake_tokens
    end

    def verify(identity_token:, email: nil, full_name: nil)
      raise VerificationError, "identity_token is required" if identity_token.blank?

      return fake_claims(identity_token, email, full_name) if @allow_fake_tokens

      verify_with_jwt!(identity_token)
    end

    private

    def fake_claims(identity_token, email, full_name)
      {
        "iss" => @issuer,
        "aud" => @audience,
        "sub" => identity_token,
        "email" => email,
        "email_verified" => email.present?,
        "name" => full_name,
        "exp" => 1.hour.from_now.to_i
      }
    end

    def verify_with_jwt!(identity_token)
      require "jwt"

      decode_with_jwks(identity_token, fetch_jwks)
    rescue JWT::DecodeError => e
      raise verification_error(e) unless key_rotation_error?(e)

      begin
        decode_with_jwks(identity_token, fetch_jwks(force: true))
      rescue JWT::DecodeError => retry_error
        raise verification_error(retry_error)
      end
    rescue LoadError
      raise VerificationError, "jwt gem is required for production Apple auth verification"
    rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error => e
      raise VerificationError, e.message
    end

    def decode_with_jwks(identity_token, jwks)
      payload, = JWT.decode(
        identity_token,
        nil,
        true,
        algorithms: [ "RS256" ],
        iss: @issuer,
        verify_iss: true,
        aud: @audience,
        verify_aud: true,
        jwks: jwks
      )

      validate_payload!(payload)
      payload
    end

    def validate_payload!(payload)
      raise VerificationError, "iss is invalid" unless payload["iss"] == @issuer
      raise VerificationError, "aud is invalid" unless Array(payload["aud"]).include?(@audience)
      raise VerificationError, "exp is required" if payload["exp"].blank?
      raise VerificationError, "exp has expired" unless Time.at(payload["exp"].to_i).future?
      raise VerificationError, "sub is required" if payload["sub"].blank?
    end

    def fetch_jwks(force: false)
      Rails.cache.delete(jwks_cache_key) if force
      Rails.cache.fetch(jwks_cache_key, expires_in: JWKS_CACHE_TTL) { request_jwks }
    end

    def request_jwks
      require "json"
      require "net/http"
      require "uri"

      response = Net::HTTP.get_response(URI(@jwks_url))
      unless response.is_a?(Net::HTTPSuccess)
        raise VerificationError, "Apple JWKS request failed with HTTP #{response.code}"
      end

      jwks = JSON.parse(response.body)
      raise VerificationError, "Apple JWKS response is invalid" unless jwks["keys"].is_a?(Array)

      jwks
    end

    def jwks_cache_key
      "apple_identity_jwks:#{@jwks_url}"
    end

    def key_rotation_error?(error)
      error.message.match?(/kid|key/i)
    end

    def verification_error(error)
      VerificationError.new(error.message)
    end
  end
end
