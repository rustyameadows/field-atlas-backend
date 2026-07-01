module Sync
  class Cursor
    class InvalidCursor < ArgumentError; end

    def self.encode(after_id)
      verifier.generate({ "after_id" => after_id.to_i })
    end

    def self.decode(cursor)
      return 0 if cursor.blank?

      verifier.verify(cursor).fetch("after_id").to_i
    rescue ActiveSupport::MessageVerifier::InvalidSignature, KeyError
      raise InvalidCursor, "Invalid sync cursor"
    end

    def self.verifier
      Rails.application.message_verifier(:sync_cursor)
    end
  end
end
