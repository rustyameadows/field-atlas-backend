require "test_helper"
require "aws-sdk-s3"

class Assets::R2ClientTest < ActiveSupport::TestCase
  test "presigned upload includes R2 endpoint method headers and content type" do
    client = Aws::S3::Client.new(
      stub_responses: true,
      region: "auto",
      endpoint: "https://account-id.r2.cloudflarestorage.com",
      credentials: Aws::Credentials.new("access-key", "secret-key")
    )
    r2 = Assets::R2Client.new(
      account_id: "account-id",
      access_key_id: "access-key",
      secret_access_key: "secret-key",
      bucket: "field-atlas-test",
      client: client
    )

    upload = r2.presigned_upload(
      storage_key: "users/user-1/assets/asset-1/trail.jpg",
      content_type: "image/jpeg",
      expires_in: 900
    )

    assert_equal "PUT", upload.fetch(:method)
    assert_includes upload.fetch(:url), "account-id.r2.cloudflarestorage.com"
    assert_includes upload.fetch(:url), "X-Amz-Signature"
    assert_equal({ "Content-Type" => "image/jpeg" }, upload.fetch(:headers))
    assert upload.fetch(:expires_at).future?
  end

  test "object metadata reads content length and type from R2" do
    client = Aws::S3::Client.new(
      stub_responses: true,
      region: "auto",
      endpoint: "https://account-id.r2.cloudflarestorage.com",
      credentials: Aws::Credentials.new("access-key", "secret-key")
    )
    client.stub_responses(:head_object, content_length: 12_345, content_type: "video/mp4")
    r2 = Assets::R2Client.new(
      account_id: "account-id",
      access_key_id: "access-key",
      secret_access_key: "secret-key",
      bucket: "field-atlas-test",
      client: client
    )

    metadata = r2.object_metadata(storage_key: "users/user-1/assets/asset-1/loop.mp4")

    assert_equal 12_345, metadata.fetch(:byte_size)
    assert_equal "video/mp4", metadata.fetch(:mime_type)
  end
end
