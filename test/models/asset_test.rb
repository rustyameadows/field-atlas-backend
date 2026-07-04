require "test_helper"

class AssetTest < ActiveSupport::TestCase
  test "asset validates generic file metadata" do
    user = User.create!(display_name: "Asset Owner", email: "asset-owner@example.com")

    asset = Asset.new(
      uploaded_by_user: user,
      client_id: "local-asset-1",
      asset_kind: "image",
      mime_type: "image/jpeg",
      original_filename: "trail.jpg",
      byte_size: 12_345,
      storage_provider: "r2",
      storage_key: "users/#{user.id}/assets/test/trail.jpg",
      status: "awaiting_upload"
    )

    assert asset.valid?
  end

  test "asset rejects unsupported kinds statuses and storage providers" do
    user = User.create!(display_name: "Asset Owner", email: "asset-invalid@example.com")
    asset = Asset.new(
      uploaded_by_user: user,
      asset_kind: "spreadsheet",
      mime_type: "application/octet-stream",
      byte_size: -1,
      storage_provider: "local_disk",
      storage_key: "bad",
      status: "done"
    )

    assert_not asset.valid?
    assert_includes asset.errors[:asset_kind], "is not included in the list"
    assert_includes asset.errors[:byte_size], "must be greater than or equal to 0"
    assert_includes asset.errors[:storage_provider], "is not included in the list"
    assert_includes asset.errors[:status], "is not included in the list"
  end

  test "asset link validates fuzzy attachable metadata" do
    user = User.create!(display_name: "Asset Owner", email: "asset-link@example.com")
    asset = Asset.create!(
      uploaded_by_user: user,
      asset_kind: "video",
      mime_type: "video/mp4",
      byte_size: 42,
      storage_provider: "r2",
      storage_key: "users/#{user.id}/assets/test/loop.mp4",
      status: "ready"
    )

    link = AssetLink.new(
      asset: asset,
      created_by_user: user,
      attachable_type: "Trip",
      attachable_id: SecureRandom.uuid,
      role: "cover_loop",
      sort_order: 1
    )

    assert link.valid?
  end

  test "asset link requires an attachable id or ref" do
    user = User.create!(display_name: "Asset Owner", email: "asset-link-invalid@example.com")
    asset = Asset.create!(
      uploaded_by_user: user,
      asset_kind: "document",
      mime_type: "application/pdf",
      byte_size: 42,
      storage_provider: "r2",
      storage_key: "users/#{user.id}/assets/test/doc.pdf",
      status: "ready"
    )

    link = AssetLink.new(
      asset: asset,
      created_by_user: user,
      attachable_type: "FutureThing",
      role: "gallery"
    )

    assert_not link.valid?
    assert_includes link.errors[:base], "attachable_id or attachable_ref is required"
  end

  test "asset indexes support common lookup paths" do
    asset_indexes = ActiveRecord::Base.connection.indexes("assets").map(&:columns)
    link_indexes = ActiveRecord::Base.connection.indexes("asset_links").map(&:columns)

    assert_includes asset_indexes, [ "uploaded_by_user_id", "created_at" ]
    assert_includes asset_indexes, [ "uploaded_by_user_id", "client_id" ]
    assert_includes link_indexes, [ "attachable_type", "attachable_id", "role", "deleted_at", "sort_order" ]
    assert_includes link_indexes, [ "asset_id" ]
  end
end
