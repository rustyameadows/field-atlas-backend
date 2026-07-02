module Auth
  class TokenDigest
    def self.digest(token)
      OpenSSL::Digest::SHA256.hexdigest(token.to_s)
    end
  end
end
