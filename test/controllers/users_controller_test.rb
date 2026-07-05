require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "dashboard renders users with device and trip counts" do
    user = User.create!(
      display_name: "Avery Field",
      email: "avery@example.com",
      email_verified: true,
      status: "active",
      username: "averyfield",
      bio: "Maps and desert roads."
    )
    asset = Asset.create!(
      uploaded_by_user: user,
      asset_kind: "image",
      mime_type: "image/jpeg",
      byte_size: 42,
      storage_provider: "r2",
      storage_key: "user_uploads/#{user.id}/test/profile.jpg",
      status: "ready"
    )
    user.update!(profile_photo_asset: asset)
    Device.create!(user: user, client_device_id: "iphone-1", name: "Avery's iPhone", platform: "ios")
    Device.create!(user: user, client_device_id: "ipad-1", name: "Avery's iPad", platform: "ios")
    Trip.create!(owner_user: user, title: "Big Bend Weekend")

    get users_path

    assert_response :success
    assert_select "h1", "Users"
    assert_select "a", text: "Places"
    assert_select "td", text: "Avery Field"
    assert_select "td", text: "averyfield"
    assert_select "td", text: "Maps and desert roads."
    assert_select "td", text: asset.id
    assert_select "td", text: "avery@example.com"
    assert_select "td", text: "active"
    assert_select "td", text: "Yes"
    assert_select "td", text: "2"
    assert_select "td", text: "1"
    assert_select "input[type=checkbox][name='user[admin]']"
  end

  test "dashboard can update the admin flag" do
    user = User.create!(
      display_name: "Casey Admin",
      email: "casey@example.com",
      email_verified: true,
      status: "active"
    )

    patch user_path(user), params: { user: { admin: "1" } }

    assert_redirected_to users_path
    assert_equal true, user.reload.admin?
  end
end
