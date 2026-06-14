require "test_helper"

class PlaceOptionsApiTest < ActionDispatch::IntegrationTest
  test "returns server-owned place kind options" do
    get "/api/v1/place_options"

    assert_response :success
    body = ::JSON.parse(response.body)
    assert_equal Place::KINDS, body.fetch("kinds")
  end
end
