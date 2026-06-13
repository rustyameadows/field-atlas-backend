module Sources
  module Nps
    class Adapter
      ENDPOINTS = {
        "park_unit" => { path: "/parks", record_type: "park" },
        "nps_place" => { path: "/places", record_type: "place" },
        "campground" => { path: "/campgrounds", record_type: "campground" },
        "visitor_center" => { path: "/visitorcenters", record_type: "visitor_center" },
        "parking_lot" => { path: "/parkinglots", record_type: "parking_lot" }
      }.freeze
      SUPPORTED_TYPES = ENDPOINTS.keys.freeze
      DEFAULT_TYPES = %w[park_unit nps_place campground visitor_center].freeze
      CHILD_TYPES = (SUPPORTED_TYPES - [ "park_unit" ]).freeze

      def initialize(client: Client.new)
        @client = client
      end

      def search(query:, limit:, types: DEFAULT_TYPES)
        return no_query_status if query.blank?

        candidates = []
        endpoint_statuses = {}

        requested_types(types).each do |type|
          config = ENDPOINTS.fetch(type)
          response = client.get(config.fetch(:path), params_for(config.fetch(:path), query, limit))
          endpoint_statuses[config.fetch(:path)] = status_for(response)

          next unless response.success?

          Array(response.body["data"]).each do |payload|
            candidates << Normalizer.new(record_type: config.fetch(:record_type), payload: payload).call
          end
        rescue MissingApiKey
          return {
            candidates: [],
            status: { source: "nps", status: "missing_key", freshness: "none", endpoints: endpoint_statuses }
          }
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, ::JSON::ParserError => error
          endpoint_statuses[config.fetch(:path)] = { status: "failed", error: error.class.name }
        end

        source_status = endpoint_statuses.values.all? { |status| status.fetch(:status) == "ok" } ? "ok" : "failed"
        {
          candidates: candidates,
          status: { source: "nps", status: source_status, freshness: "live", endpoints: endpoint_statuses }
        }
      end

      def search_within_place(place:, limit:, start: 0, types: CHILD_TYPES)
        park_code = park_code_for(place)
        return no_provider_code_status if park_code.blank?

        candidates = []
        endpoint_statuses = {}

        requested_child_types(types).each do |type|
          config = ENDPOINTS.fetch(type)
          response = client.get(config.fetch(:path), "parkCode" => park_code, "limit" => limit.to_s, "start" => start.to_s)
          endpoint_statuses[config.fetch(:path)] = status_for(response)

          next unless response.success?

          Array(response.body["data"]).each do |payload|
            candidates << Normalizer.new(record_type: config.fetch(:record_type), payload: payload).call
          end
        rescue MissingApiKey
          return {
            candidates: [],
            status: { source: "nps", status: "missing_key", freshness: "none", endpoints: endpoint_statuses }
          }
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, ::JSON::ParserError => error
          endpoint_statuses[config.fetch(:path)] = { status: "failed", error: error.class.name }
        end

        source_status = endpoint_statuses.values.all? { |status| status.fetch(:status) == "ok" } ? "ok" : "failed"
        {
          candidates: candidates,
          status: { source: "nps", status: source_status, freshness: "live", endpoints: endpoint_statuses }
        }
      end

      private

      attr_reader :client

      def requested_child_types(types)
        requested_types(types).intersection(CHILD_TYPES).presence || CHILD_TYPES
      end

      def requested_types(types)
        requested = Array(types).presence || DEFAULT_TYPES
        requested.intersection(SUPPORTED_TYPES)
      end

      def params_for(path, query, limit)
        params = { "q" => query, "limit" => limit.to_s }
        params["sort"] = "-relevanceScore" if path == "/parks"
        params
      end

      def status_for(response)
        return { status: "ok", http_status: response.status } if response.success?

        {
          status: "failed",
          http_status: response.status,
          rate_limit_remaining: response.headers["x-ratelimit-remaining"]
        }.compact
      end

      def no_query_status
        {
          candidates: [],
          status: { source: "nps", status: "skipped", freshness: "stored", reason: "blank_query" }
        }
      end

      def no_provider_code_status
        {
          candidates: [],
          status: { source: "nps", status: "skipped", freshness: "stored", reason: "missing_provider_code" }
        }
      end

      def park_code_for(place)
        place.metadata.dig("provider_codes", "nps").presence ||
          place.park_unit&.official_code.presence ||
          place.source_records.where(provider: "nps", record_type: "park").pick(:source_id)
      end
    end
  end
end
