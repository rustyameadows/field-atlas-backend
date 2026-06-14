require "test_helper"

class PlaceExternalIdentifierTest < ActiveSupport::TestCase
  test "allows one place to have many provider identifiers" do
    place = create_place

    primary = PlaceExternalIdentifier.create!(
      place: place,
      provider: "mapkit",
      identifier: "mapkit-primary",
      identifier_kind: "primary",
      review_status: "verified"
    )
    alternate = PlaceExternalIdentifier.create!(
      place: place,
      provider: "mapkit",
      identifier: "mapkit-alternate",
      identifier_kind: "alternate",
      review_status: "verified"
    )

    assert_equal [ primary, alternate ], place.external_identifiers.order(:id).to_a
    assert_equal({ "mapkit" => [ "mapkit-primary", "mapkit-alternate" ] }, place.source_ids_by_provider)
  end

  test "does not allow one provider identifier to point at two places" do
    first_place = create_place(slug: "first-place")
    second_place = create_place(slug: "second-place")

    PlaceExternalIdentifier.create!(
      place: first_place,
      provider: "mapkit",
      identifier: "shared-mapkit-id"
    )

    duplicate = PlaceExternalIdentifier.new(
      place: second_place,
      provider: "mapkit",
      identifier: "shared-mapkit-id"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:identifier], "has already been taken"
  end

  test "requires provider and identifier" do
    identifier = PlaceExternalIdentifier.new(
      place: create_place,
      provider: " ",
      identifier: " "
    )

    assert_not identifier.valid?
    assert_includes identifier.errors[:provider], "can't be blank"
    assert_includes identifier.errors[:identifier], "can't be blank"
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
