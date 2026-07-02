module Auth
  class SessionIssuer
    ACCESS_TOKEN_TTL = 1.hour
    REFRESH_TOKEN_TTL = 30.days

    def self.issue(user:, device: nil)
      new(user: user, device: device).issue
    end

    def self.refresh!(session)
      new(user: session.user, device: session.device).refresh!(session)
    end

    def initialize(user:, device:)
      @user = user
      @device = device
    end

    def issue
      access_token = token
      refresh_token = token
      api_session = ApiSession.create!(
        user: @user,
        device: @device,
        access_token_digest: TokenDigest.digest(access_token),
        refresh_token_digest: TokenDigest.digest(refresh_token),
        expires_at: ACCESS_TOKEN_TTL.from_now,
        refresh_expires_at: REFRESH_TOKEN_TTL.from_now,
        last_used_at: Time.current
      )

      [ api_session, access_token, refresh_token ]
    end

    def refresh!(session)
      access_token = token
      refresh_token = token
      session.update!(
        access_token_digest: TokenDigest.digest(access_token),
        refresh_token_digest: TokenDigest.digest(refresh_token),
        expires_at: ACCESS_TOKEN_TTL.from_now,
        refresh_expires_at: REFRESH_TOKEN_TTL.from_now,
        last_used_at: Time.current
      )

      [ session, access_token, refresh_token ]
    end

    private

    def token
      SecureRandom.urlsafe_base64(48)
    end
  end
end
