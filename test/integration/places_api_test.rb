require "test_helper"

class PlacesApiTest < ActionDispatch::IntegrationTest
  test "creates a published canonical place with a generated slug" do
    post "/api/v1/places", params: {
      name: "Hidden Valley Picnic Area",
      kind: "poi",
      primary_category: "picnic_area",
      coordinate: { lat: 34.0124, lng: -116.167 }
    }, as: :json

    assert_response :created
    body = ::JSON.parse(response.body)
    assert_equal "Hidden Valley Picnic Area", body.fetch("name")
    assert_equal "hidden-valley-picnic-area", body.fetch("slug")
    assert_equal "poi", body.fetch("kind")
    assert_equal "published", body.fetch("status")
    assert_equal "picnic_area", body.fetch("primary_category")
    assert_equal({ "lat" => 34.0124, "lng" => -116.167 }, body.fetch("coordinate"))
    assert_equal({}, body.fetch("source_ids"))

    place = Place.find(body.fetch("id"))
    assert_equal "Hidden Valley Picnic Area", place.name
    assert_equal "hidden-valley-picnic-area", place.slug
    assert_not_nil place.centroid
  end

  test "honors an explicit draft status" do
    post "/api/v1/places", params: {
      name: "Unreviewed Trailhead",
      kind: "trailhead",
      status: "draft"
    }, as: :json

    assert_response :created
    assert_equal "draft", ::JSON.parse(response.body).fetch("status")
  end

  test "creates a canonical place from a wrapped place payload" do
    post "/api/v1/places", params: {
      place: {
        name: "Cottonwood Campground",
        slug: "cottonwood-campground-jotr",
        kind: "campground",
        status: "published"
      }
    }, as: :json

    assert_response :created
    body = ::JSON.parse(response.body)
    assert_equal "Cottonwood Campground", body.fetch("name")
    assert_equal "cottonwood-campground-jotr", body.fetch("slug")
    assert_equal "campground", body.fetch("kind")
    assert_equal "published", body.fetch("status")
  end

  test "creates a canonical place with provider associations" do
    post "/api/v1/places", params: {
      place: {
        name: "Hidden Valley Trailhead",
        kind: "trailhead"
      },
      associations: [
        {
          provider: "mapkit",
          identifiers: [
            { identifier: "mapkit-hidden-valley", identifier_kind: "primary" },
            { identifier: "mapkit-hidden-valley-alt", identifier_kind: "alternate" }
          ]
        },
        {
          provider: "nps",
          identifiers: [
            { identifier: "hidden-valley-trailhead" }
          ]
        }
      ]
    }, as: :json

    assert_response :created
    body = ::JSON.parse(response.body)
    place = Place.find(body.fetch("id"))
    assert_equal [ "mapkit-hidden-valley", "mapkit-hidden-valley-alt" ], body.fetch("source_ids").fetch("mapkit")
    assert_equal [ "hidden-valley-trailhead" ], body.fetch("source_ids").fetch("nps")
    assert_equal 3, place.external_identifiers.count
    assert_equal [ "verified" ], place.external_identifiers.distinct.pluck(:review_status)
  end

  test "creates a canonical place with shorthand provider identifiers" do
    post "/api/v1/places", params: {
      name: "Keys View",
      kind: "scenic_point",
      provider: "mapkit",
      identifiers: [
        { identifier: "mapkit-keys-view" }
      ]
    }, as: :json

    assert_response :created
    body = ::JSON.parse(response.body)
    assert_equal [ "mapkit-keys-view" ], body.fetch("source_ids").fetch("mapkit")
  end

  test "does not create a place when an association conflicts" do
    existing_place = Place.create!(
      name: "Existing Keys View",
      slug: "existing-keys-view",
      kind: "scenic_point",
      status: "published"
    )
    PlaceExternalIdentifier.create!(place: existing_place, provider: "mapkit", identifier: "mapkit-keys-view")

    post "/api/v1/places", params: {
      name: "New Keys View",
      kind: "scenic_point",
      provider: "mapkit",
      identifiers: [
        { identifier: "mapkit-keys-view" }
      ]
    }, as: :json

    assert_response :unprocessable_content
    assert_includes ::JSON.parse(response.body).fetch("errors"), "Identifier has already been taken"
    assert_nil Place.find_by(slug: "new-keys-view")
  end

  test "returns validation errors for missing required fields" do
    post "/api/v1/places", params: {
      name: " ",
      kind: "poi"
    }, as: :json

    assert_response :unprocessable_content
    assert_includes ::JSON.parse(response.body).fetch("errors"), "Name can't be blank"
  end

  test "returns validation errors for duplicate slugs" do
    Place.create!(
      name: "Hidden Valley Picnic Area",
      slug: "hidden-valley-picnic-area",
      kind: "poi",
      status: "draft"
    )

    post "/api/v1/places", params: {
      name: "Hidden Valley Picnic Area",
      kind: "poi"
    }, as: :json

    assert_response :unprocessable_content
    assert_includes ::JSON.parse(response.body).fetch("errors"), "Slug has already been taken"
  end

  test "returns validation errors for incomplete coordinates" do
    post "/api/v1/places", params: {
      name: "Keys View",
      kind: "scenic_point",
      coordinate: { lat: 33.927 }
    }, as: :json

    assert_response :unprocessable_content
    assert_includes ::JSON.parse(response.body).fetch("errors"), "coordinate requires lat and lng"
  end
end
