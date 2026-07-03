require "aws-sdk-s3"

module Assets
  class R2Client
    class ConfigurationError < StandardError; end
    class ObjectNotFound < StandardError; end

    DEFAULT_EXPIRY = 15.minutes

    def initialize(
      account_id: ENV["CLOUDFLARE_R2_ACCOUNT_ID"],
      access_key_id: ENV["CLOUDFLARE_R2_ACCESS_KEY_ID"],
      secret_access_key: ENV["CLOUDFLARE_R2_SECRET_ACCESS_KEY"],
      bucket: ENV["CLOUDFLARE_R2_BUCKET"],
      client: nil
    )
      @account_id = account_id
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @bucket = bucket
      validate_configuration!
      @client = client || build_client
      @presigner = Aws::S3::Presigner.new(client: @client)
    end

    def presigned_upload(storage_key:, content_type:, expires_in: DEFAULT_EXPIRY.to_i)
      expires_at = expires_in.to_i.seconds.from_now
      {
        method: "PUT",
        url: @presigner.presigned_url(
          :put_object,
          bucket: @bucket,
          key: storage_key,
          content_type: content_type,
          expires_in: expires_in.to_i
        ),
        headers: { "Content-Type" => content_type },
        expires_at: expires_at
      }
    end

    def presigned_download(storage_key:, expires_in: DEFAULT_EXPIRY.to_i)
      expires_at = expires_in.to_i.seconds.from_now
      {
        method: "GET",
        url: @presigner.presigned_url(
          :get_object,
          bucket: @bucket,
          key: storage_key,
          expires_in: expires_in.to_i
        ),
        headers: {},
        expires_at: expires_at
      }
    end

    def object_metadata(storage_key:)
      response = @client.head_object(bucket: @bucket, key: storage_key)
      {
        byte_size: response.content_length,
        mime_type: response.content_type
      }
    rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
      raise ObjectNotFound, "R2 object was not found"
    end

    private

    def build_client
      Aws::S3::Client.new(
        access_key_id: @access_key_id,
        secret_access_key: @secret_access_key,
        endpoint: "https://#{@account_id}.r2.cloudflarestorage.com",
        region: "auto"
      )
    end

    def validate_configuration!
      missing = {
        "CLOUDFLARE_R2_ACCOUNT_ID" => @account_id,
        "CLOUDFLARE_R2_ACCESS_KEY_ID" => @access_key_id,
        "CLOUDFLARE_R2_SECRET_ACCESS_KEY" => @secret_access_key,
        "CLOUDFLARE_R2_BUCKET" => @bucket
      }.filter_map { |key, value| key if value.blank? }

      return if missing.empty?

      raise ConfigurationError, "Missing Cloudflare R2 configuration: #{missing.join(", ")}"
    end
  end
end
