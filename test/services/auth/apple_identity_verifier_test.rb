require "test_helper"
require "digest"
require "jwt"
require "openssl"

class Auth::AppleIdentityVerifierTest < ActiveSupport::TestCase
  ISSUER = "https://appleid.apple.com"
  AUDIENCE = "com.rustymeadows.DestinationApp"
  JWKS_URL = "https://apple.test/auth/keys"

  setup do
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear

    @key = OpenSSL::PKey::RSA.generate(2048)
    @kid = "apple-key-1"
    @verifier = Auth::AppleIdentityVerifier.new(
      audience: AUDIENCE,
      issuer: ISSUER,
      jwks_url: JWKS_URL,
      allow_fake_tokens: false
    )
  end

  teardown do
    Rails.cache.clear
    Rails.cache = @previous_cache
  end

  test "valid signed identity token returns claims" do
    stub_jwks(@key, @kid)

    claims = @verifier.verify(identity_token: apple_token(sub: "apple-user-1"))

    assert_equal ISSUER, claims.fetch("iss")
    assert_equal AUDIENCE, claims.fetch("aud")
    assert_equal "apple-user-1", claims.fetch("sub")
  end

  test "wrong audience is rejected" do
    stub_jwks(@key, @kid)

    error = assert_raises(Auth::AppleIdentityVerifier::VerificationError) do
      @verifier.verify(identity_token: apple_token(aud: "wrong-client-id"))
    end

    assert_match(/aud/i, error.message)
  end

  test "wrong issuer is rejected" do
    stub_jwks(@key, @kid)

    error = assert_raises(Auth::AppleIdentityVerifier::VerificationError) do
      @verifier.verify(identity_token: apple_token(iss: "https://example.com"))
    end

    assert_match(/issuer|iss/i, error.message)
  end

  test "expired token is rejected" do
    stub_jwks(@key, @kid)

    error = assert_raises(Auth::AppleIdentityVerifier::VerificationError) do
      @verifier.verify(identity_token: apple_token(exp: 1.hour.ago.to_i))
    end

    assert_match(/expired|exp/i, error.message)
  end

  test "missing subject is rejected" do
    stub_jwks(@key, @kid)

    error = assert_raises(Auth::AppleIdentityVerifier::VerificationError) do
      @verifier.verify(identity_token: apple_token(sub: nil))
    end

    assert_match(/sub/i, error.message)
  end

  test "raw nonce is hashed and matched against token nonce claim" do
    stub_jwks(@key, @kid)
    raw_nonce = "raw-nonce-from-ios"

    claims = @verifier.verify(
      identity_token: apple_token(nonce: Digest::SHA256.hexdigest(raw_nonce)),
      nonce: raw_nonce
    )

    assert_equal Digest::SHA256.hexdigest(raw_nonce), claims.fetch("nonce")
  end

  test "nonce mismatch is rejected" do
    stub_jwks(@key, @kid)

    error = assert_raises(Auth::AppleIdentityVerifier::VerificationError) do
      @verifier.verify(
        identity_token: apple_token(nonce: Digest::SHA256.hexdigest("different-raw-nonce")),
        nonce: "raw-nonce-from-ios"
      )
    end

    assert_match(/nonce/i, error.message)
  end

  test "missing token nonce is rejected when raw nonce is supplied" do
    stub_jwks(@key, @kid)

    error = assert_raises(Auth::AppleIdentityVerifier::VerificationError) do
      @verifier.verify(identity_token: apple_token, nonce: "raw-nonce-from-ios")
    end

    assert_match(/nonce/i, error.message)
  end

  test "rotated signing key refreshes jwks once" do
    stale_key = OpenSSL::PKey::RSA.generate(2048)
    stale_kid = "stale-key"
    stub_request(:get, JWKS_URL).to_return(
      {
        status: 200,
        body: jwks_body(stale_key, stale_kid),
        headers: { "Content-Type" => "application/json" }
      },
      {
        status: 200,
        body: jwks_body(@key, @kid),
        headers: { "Content-Type" => "application/json" }
      }
    )

    claims = @verifier.verify(identity_token: apple_token(sub: "apple-user-rotated"))

    assert_equal "apple-user-rotated", claims.fetch("sub")
    assert_requested :get, JWKS_URL, times: 2
  end

  test "missing signing key after refresh is rejected cleanly" do
    stale_key = OpenSSL::PKey::RSA.generate(2048)
    stale_kid = "stale-key"
    other_key = OpenSSL::PKey::RSA.generate(2048)
    other_kid = "other-key"
    stub_request(:get, JWKS_URL).to_return(
      {
        status: 200,
        body: jwks_body(stale_key, stale_kid),
        headers: { "Content-Type" => "application/json" }
      },
      {
        status: 200,
        body: jwks_body(other_key, other_kid),
        headers: { "Content-Type" => "application/json" }
      }
    )

    error = assert_raises(Auth::AppleIdentityVerifier::VerificationError) do
      @verifier.verify(identity_token: apple_token(sub: "apple-user-missing-key"))
    end

    assert_match(/kid|key/i, error.message)
    assert_requested :get, JWKS_URL, times: 2
  end


  private

  def apple_token(sub: "apple-user-1", aud: AUDIENCE, iss: ISSUER, exp: 1.hour.from_now.to_i, nonce: nil, kid: @kid, key: @key)
    payload = {
      "iss" => iss,
      "aud" => aud,
      "exp" => exp,
      "iat" => Time.current.to_i,
      "sub" => sub,
      "nonce" => nonce,
      "email" => "avery@example.com",
      "email_verified" => "true"
    }.compact

    JWT.encode(payload, key, "RS256", kid: kid)
  end

  def stub_jwks(key, kid)
    stub_request(:get, JWKS_URL).to_return(
      status: 200,
      body: jwks_body(key, kid),
      headers: { "Content-Type" => "application/json" }
    )
  end

  def jwks_body(key, kid)
    jwk = JWT::JWK.new(key.public_key, kid).export
    { keys: [ jwk.merge(alg: "RS256", use: "sig") ] }.to_json
  end
end
