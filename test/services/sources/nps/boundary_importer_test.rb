require "test_helper"

class Sources::Nps::BoundaryImporterTest < ActiveSupport::TestCase
  test "imports GeoJSON park boundaries into canonical place geometry" do
    place = create_nps_park_place
    original_centroid = place.centroid
    client = FakeNpsClient.new(
      "/mapdata/parkboundaries/jotr" => feature_collection(
        {
          "type" => "MultiPolygon",
          "coordinates" => [
            [
              [
                [ -116.1, 34.1 ],
                [ -116.0, 34.1 ],
                [ -116.0, 34.0 ],
                [ -116.1, 34.0 ],
                [ -116.1, 34.1 ]
              ]
            ]
          ]
        }
      )
    )

    result = Sources::Nps::BoundaryImporter.new(client: client).call

    assert_equal 1, result.checked
    assert_equal 1, result.updated
    assert_empty result.missing
    assert_empty result.failed
    assert_equal [ [ "/mapdata/parkboundaries/jotr", {} ] ], client.requests

    place.reload
    assert_equal "ST_MultiPolygon", geometry_type(place)
    assert_equal original_centroid, place.centroid
    assert_equal false, geometry_equals_centroid?(place)
  end

  test "records missing boundaries without changing existing geometry" do
    place = create_nps_park_place
    original_geometry = place.geometry
    client = FakeNpsClient.new(
      "/mapdata/parkboundaries/jotr" => feature_collection(nil)
    )

    result = Sources::Nps::BoundaryImporter.new(client: client).call

    assert_equal 1, result.checked
    assert_equal 0, result.updated
    assert_equal [ { place_id: place.id, park_code: "jotr", reason: "missing_geometry" } ], result.missing
    assert_empty result.failed
    assert_equal original_geometry, place.reload.geometry
  end

  private

  def create_nps_park_place
    Place.create!(
      name: "Joshua Tree National Park",
      slug: "joshua-tree-national-park",
      kind: "park_unit",
      status: "published",
      primary_category: "national_park",
      geometry: Places::Geo.point(lng: -115.8398125, lat: 33.91418525),
      centroid: Places::Geo.point(lng: -115.8398125, lat: 33.91418525)
    ).tap do |place|
      place.create_park_unit!(
        agency: "nps",
        designation: "National Park",
        states: [ "CA" ],
        official_code: "jotr",
        source_provider: "nps"
      )
    end
  end

  def feature_collection(geometry)
    features = []
    features << { "type" => "Feature", "geometry" => geometry, "properties" => { "fullName" => "Joshua Tree National Park" } } if geometry

    {
      "type" => "FeatureCollection",
      "features" => features
    }
  end

  def geometry_type(place)
    ActiveRecord::Base.connection.select_value(
      Place.where(id: place.id).select("ST_GeometryType(geometry::geometry)").to_sql
    )
  end

  def geometry_equals_centroid?(place)
    ActiveRecord::Base.connection.select_value(
      Place.where(id: place.id).select("ST_Equals(geometry::geometry, centroid::geometry)").to_sql
    )
  end

  class FakeNpsClient
    Response = Data.define(:status, :body, :headers) do
      def success?
        status.between?(200, 299)
      end
    end

    attr_reader :requests

    def initialize(responses_by_path)
      @responses_by_path = responses_by_path
      @requests = []
    end

    def get(path, params = {})
      requests << [ path, params ]
      Response.new(200, responses_by_path.fetch(path), {})
    end

    private

    attr_reader :responses_by_path
  end
end
