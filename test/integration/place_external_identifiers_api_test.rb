require "test_helper"

class PlaceExternalIdentifiersApiTest < ActionDispatch::IntegrationTest
  test "creates verified provider identifiers for a canonical place" do
    place = create_place

    post "/api/v1/place_external_identifiers", params: {
      place_id: place.id,
      provider: "mapkit",
      identifiers: [
        { identifier: "mapkit-primary", identifier_kind: "primary" },
        { identifier: "mapkit-alternate", identifier_kind: "alternate" }
      ]
    }, as: :json

    assert_response :success
    body = ::JSON.parse(response.body)
    assert_equal place.id, body.fetch("place_id")
    assert_equal [ "mapkit-primary", "mapkit-alternate" ], body.fetch("source_ids").fetch("mapkit")

    assert_equal 2, place.external_identifiers.count
    assert_equal [ "alternate", "primary" ], place.external_identifiers.order(:identifier_kind).pluck(:identifier_kind)
    assert_equal [ "verified" ], place.external_identifiers.distinct.pluck(:review_status)
  end

  test "repeating the same association is idempotent" do
    place = create_place
    payload = {
      place_id: place.id,
      provider: "mapkit",
      identifiers: [
        { identifier: "mapkit-primary", identifier_kind: "primary" }
      ]
    }

    2.times do
      post "/api/v1/place_external_identifiers", params: payload, as: :json
      assert_response :success
    end

    assert_equal 1, place.external_identifiers.count
    assert_equal [ "mapkit-primary" ], ::JSON.parse(response.body).fetch("source_ids").fetch("mapkit")
  end

  test "adds a later alternate identifier without removing existing identifiers" do
    place = create_place
    PlaceExternalIdentifier.create!(place: place, provider: "mapkit", identifier: "mapkit-primary")

    post "/api/v1/place_external_identifiers", params: {
      place_id: place.id,
      provider: "mapkit",
      identifiers: [
        { identifier: "mapkit-alternate", identifier_kind: "alternate" }
      ]
    }, as: :json

    assert_response :success
    assert_equal [ "mapkit-primary", "mapkit-alternate" ], ::JSON.parse(response.body).fetch("source_ids").fetch("mapkit")
  end

  test "returns not found for a missing place" do
    post "/api/v1/place_external_identifiers", params: {
      place_id: 99_999,
      provider: "mapkit",
      identifiers: [
        { identifier: "mapkit-primary" }
      ]
    }, as: :json

    assert_response :not_found
    assert_equal "Place not found", ::JSON.parse(response.body).fetch("error")
  end

  test "returns validation errors for blank identifiers" do
    place = create_place

    post "/api/v1/place_external_identifiers", params: {
      place_id: place.id,
      provider: "mapkit",
      identifiers: [
        { identifier: " " }
      ]
    }, as: :json

    assert_response :unprocessable_content
    assert_includes ::JSON.parse(response.body).fetch("errors"), "identifier can't be blank"
  end

  test "returns validation errors when an identifier belongs to another place" do
    first_place = create_place(slug: "first-place")
    second_place = create_place(slug: "second-place")
    PlaceExternalIdentifier.create!(place: first_place, provider: "mapkit", identifier: "mapkit-primary")

    post "/api/v1/place_external_identifiers", params: {
      place_id: second_place.id,
      provider: "mapkit",
      identifiers: [
        { identifier: "mapkit-primary" }
      ]
    }, as: :json

    assert_response :unprocessable_content
    assert_includes ::JSON.parse(response.body).fetch("errors"), "mapkit identifier mapkit-primary already belongs to place #{first_place.id}"
  end

  private

  def create_place(slug: "joshua-tree-national-park")
    Place.create!(
      name: slug.titleize,
      slug: slug,
      kind: "park_unit",
      status: "published",
      primary_category: "national_park"
    )
  end
end
