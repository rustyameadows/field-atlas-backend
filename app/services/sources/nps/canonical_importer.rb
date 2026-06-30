module Sources
  module Nps
    class CanonicalImporter
      DEFAULT_PAGE_LIMIT = 50
      ENDPOINTS = [
        { path: "/parks", record_type: "park" },
        { path: "/campgrounds", record_type: "campground" },
        { path: "/visitorcenters", record_type: "visitor_center" }
      ].freeze

      Result = Data.define(:fetched, :source_records, :places, :links, :containments, :skipped)

      def initialize(client: Client.new, page_limit: DEFAULT_PAGE_LIMIT)
        @client = client
        @page_limit = page_limit
      end

      def call
        stats = {
          fetched: Hash.new(0),
          source_records: Hash.new(0),
          places: Hash.new(0),
          links: 0,
          containments: 0,
          skipped: []
        }

        ENDPOINTS.each do |endpoint|
          import_endpoint(endpoint, stats)
        end

        Result.new(
          fetched: stats.fetch(:fetched).to_h,
          source_records: stats.fetch(:source_records).to_h,
          places: stats.fetch(:places).to_h,
          links: stats.fetch(:links),
          containments: stats.fetch(:containments),
          skipped: stats.fetch(:skipped)
        )
      end

      private

      attr_reader :client, :page_limit

      def import_endpoint(endpoint, stats)
        each_payload(endpoint.fetch(:path)) do |payload|
          normalized = Normalizer.new(record_type: endpoint.fetch(:record_type), payload: payload).call
          source_record = upsert.call(normalized)
          stats.fetch(:fetched)[source_record.record_type] += 1
          stats.fetch(:source_records)[source_record.record_type] += 1

          promote(source_record, stats)
        end
      end

      def each_payload(path)
        start = 0

        loop do
          response = client.get(path, "limit" => page_limit.to_s, "start" => start.to_s)
          raise "NPS #{path} import failed with status #{response.status}" unless response.success?

          body = response.body
          data = Array(body["data"])
          data.each { |payload| yield payload }

          total = body["total"].to_i
          returned_limit = body["limit"].presence&.to_i || page_limit
          start += returned_limit
          break if total.zero? || start >= total || data.blank?
        end
      end

      def promote(source_record, stats)
        before_places = Place.count
        before_links = PlaceSourceLink.count
        before_containments = PlaceContainment.count

        case source_record.record_type
        when "park"
          Places::SourceRecordPromotion.new(source_record).call
        when "campground", "visitor_center"
          Sources::Nps::ChildPlacePromotion.new(source_record).call
        end

        stats.fetch(:places)[source_record.record_type] += Place.count - before_places
        stats[:links] += PlaceSourceLink.count - before_links
        stats[:containments] += PlaceContainment.count - before_containments
      rescue Sources::Nps::ChildPlacePromotion::MissingParentPark
        stats.fetch(:skipped) << {
          record_type: source_record.record_type,
          source_id: source_record.source_id,
          name: source_record.name,
          park_code: source_record.normalized_payload["park_code"],
          reason: "missing_parent_park"
        }
      end

      def upsert
        @upsert ||= Places::SourceRecordUpsert.new(dataset: dataset)
      end

      def dataset
        @dataset ||= SourceDataset.find_or_create_by!(provider: "nps", name: "National Park Service") do |source_dataset|
          source_dataset.source_url = Client::BASE_URL
          source_dataset.freshness_mode = "live_query"
          source_dataset.status = "active"
        end
      end
    end
  end
end
