module Assets
  class StorageKey
    def self.generate(user:, original_filename:)
      filename = sanitize_filename(original_filename)
      "user_uploads/#{user.id}/#{SecureRandom.uuid}/#{filename}"
    end

    def self.sanitize_filename(filename)
      basename = File.basename(filename.to_s).presence || "asset"
      basename.gsub(/[^A-Za-z0-9.\-_]/, "-")
    end
  end
end
