require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "profile fields are optional" do
    user = User.new(
      display_name: "Profile Optional",
      email: "profile-optional@example.com",
      username: nil,
      bio: nil,
      profile_photo_asset: nil
    )

    assert user.valid?
  end

  test "username is case-insensitively unique and preserves client value" do
    User.create!(
      display_name: "Rusty Meadows",
      email: "username-owner@example.com",
      username: "@RaMeadows"
    )
    duplicate = User.new(
      display_name: "Other User",
      email: "username-duplicate@example.com",
      username: "@rameadows"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:username], "has already been taken"
    assert_equal "@RaMeadows", User.find_by!(email: "username-owner@example.com").username
  end

  test "profile photo must be a ready image uploaded by the user" do
    user = User.create!(display_name: "Photo Owner", email: "photo-owner@example.com")
    other_user = User.create!(display_name: "Photo Other", email: "photo-other@example.com")
    ready_image = create_asset(user: user, asset_kind: "image", mime_type: "image/jpeg", status: "ready", filename: "profile.jpg")
    other_ready_image = create_asset(user: other_user, asset_kind: "image", mime_type: "image/jpeg", status: "ready", filename: "other.jpg")
    ready_video = create_asset(user: user, asset_kind: "video", mime_type: "video/mp4", status: "ready", filename: "clip.mp4")
    awaiting_image = create_asset(user: user, asset_kind: "image", mime_type: "image/jpeg", status: "awaiting_upload", filename: "pending.jpg")

    user.profile_photo_asset = ready_image
    assert user.valid?

    wrong_owner = User.new(display_name: "Wrong Owner", email: "wrong-owner@example.com", profile_photo_asset: other_ready_image)
    assert_not wrong_owner.valid?
    assert_includes wrong_owner.errors[:profile_photo_asset], "must be a ready image uploaded by the user"

    wrong_kind = User.new(display_name: "Wrong Kind", email: "wrong-kind@example.com", profile_photo_asset: ready_video)
    assert_not wrong_kind.valid?
    assert_includes wrong_kind.errors[:profile_photo_asset], "must be a ready image uploaded by the user"

    not_ready = User.new(display_name: "Not Ready", email: "not-ready@example.com", profile_photo_asset: awaiting_image)
    assert_not not_ready.valid?
    assert_includes not_ready.errors[:profile_photo_asset], "must be a ready image uploaded by the user"
  end

  private

  def create_asset(user:, asset_kind:, mime_type:, status:, filename:)
    Asset.create!(
      uploaded_by_user: user,
      asset_kind: asset_kind,
      mime_type: mime_type,
      original_filename: filename,
      byte_size: 1_024,
      storage_provider: "r2",
      storage_key: "user_uploads/#{user.id}/test/#{SecureRandom.uuid}/#{filename}",
      status: status
    )
  end
end
