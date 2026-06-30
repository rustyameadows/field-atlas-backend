require "test_helper"

class Sources::Nps::CanonicalImporterTest < ActiveSupport::TestCase
  test "imports paginated parks then promotes campgrounds and visitor centers" do
    importer = Sources::Nps::CanonicalImporter.new(client: fake_client, page_limit: 1)

    result = importer.call

    assert_equal 2, result.fetched.fetch("park")
    assert_equal 1, result.fetched.fetch("campground")
    assert_equal 1, result.fetched.fetch("visitor_center")
    assert_empty result.skipped

    assert_equal 2, Place.where(kind: "park_unit").count
    assert_equal 1, Place.where(kind: "campground", primary_category: "campground").count
    assert_equal 1, Place.where(kind: "poi", primary_category: "visitor_center").count
    assert_equal 4, SourceRecord.where(provider: "nps").count
    assert_equal 4, PlaceSourceLink.joins(:source_record).where(source_records: { provider: "nps" }).count
    assert_equal 2, PlaceContainment.count

    campground = Place.find_by!(name: "Pinnacles Campground")
    visitor_center = Place.find_by!(name: "Bear Gulch Nature Center")
    parent = ParkUnit.find_by!(official_code: "pinn").place

    assert_equal [ "B55ABE9A-E5AF-4A4E-AACE-7299165831F5" ], campground.source_ids_by_provider.fetch("nps")
    assert_equal [ "5CF88A2F-F820-44EA-8E24-E1312942DA57" ], visitor_center.source_ids_by_provider.fetch("nps")
    assert_equal [ parent ], campground.source_records.first.containing_places
    assert_equal [ parent ], visitor_center.source_records.first.containing_places
    assert_equal "national_park", parent.primary_category
  end

  test "rerunning the import does not duplicate records or links" do
    importer = Sources::Nps::CanonicalImporter.new(client: fake_client, page_limit: 1)

    2.times { importer.call }

    assert_equal 4, SourceRecord.where(provider: "nps").count
    assert_equal 4, Place.count
    assert_equal 4, PlaceSourceLink.count
    assert_equal 2, PlaceContainment.count
  end

  test "skips child records when the parent park is missing" do
    client = FakeNpsClient.new(
      "/parks" => [ page(total: 0, data: []) ],
      "/campgrounds" => [ page(total: 1, data: [ campground_payload.merge("parkCode" => "missing") ]) ],
      "/visitorcenters" => [ page(total: 0, data: []) ]
    )

    result = Sources::Nps::CanonicalImporter.new(client: client, page_limit: 50).call

    assert_equal 1, SourceRecord.where(provider: "nps", record_type: "campground").count
    assert_equal 0, Place.where(kind: "campground").count
    assert_equal [
      {
        record_type: "campground",
        source_id: "B55ABE9A-E5AF-4A4E-AACE-7299165831F5",
        name: "Pinnacles Campground",
        park_code: "missing",
        reason: "missing_parent_park"
      }
    ], result.skipped
  end

  test "promoted child places are returned as canonical search results" do
    Sources::Nps::CanonicalImporter.new(client: fake_client, page_limit: 1).call

    results = Places::Search.new({ q: "Pinnacles Campground", sources: "field_atlas", limit: 10 }).call.fetch(:results)

    assert_equal [ "canonical_place" ], results.map { |result| result.fetch(:result_type) }
    assert_equal "Pinnacles Campground", results.first.fetch(:name)
    assert_equal "campground", results.first.fetch(:category)
    assert_equal [ "B55ABE9A-E5AF-4A4E-AACE-7299165831F5" ], results.first.fetch(:source_ids).fetch("nps")
    assert_equal "Pinnacles National Park", results.first.fetch(:containing_place_name)
  end

  private

  def fake_client
    FakeNpsClient.new(
      "/parks" => [
        page(total: 2, data: [ pinnacles_payload ], limit: 1, start: 0),
        page(total: 2, data: [ joshua_tree_payload ], limit: 1, start: 1)
      ],
      "/campgrounds" => [ page(total: 1, data: [ campground_payload ]) ],
      "/visitorcenters" => [ page(total: 1, data: [ visitor_center_payload ]) ]
    )
  end

  def page(total:, data:, limit: 50, start: 0)
    {
      "total" => total.to_s,
      "limit" => limit.to_s,
      "start" => start.to_s,
      "data" => data
    }
  end

  def pinnacles_payload
    json_fixture("nps/parks_pinnacles.json").fetch("data").first
  end

  def joshua_tree_payload
    pinnacles_payload.merge(
      "parkCode" => "jotr",
      "fullName" => "Joshua Tree National Park",
      "name" => "Joshua Tree",
      "latitude" => "33.8734",
      "longitude" => "-115.9010"
    )
  end

  def campground_payload
    json_fixture("nps/campgrounds_pinnacles.json").fetch("data").first
  end

  def visitor_center_payload
    json_fixture("nps/visitorcenters_pinnacles.json").fetch("data").first
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
      pages = responses_by_path.fetch(path)
      page = pages.find { |candidate| candidate.fetch("start").to_s == params.fetch("start", "0").to_s } || pages.first
      Response.new(200, page, {})
    end

    private

    attr_reader :responses_by_path
  end
end
