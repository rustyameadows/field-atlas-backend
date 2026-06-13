require "set"

module Places
  class Search
    DEFAULT_LIMIT = 10
    DEFAULT_SOURCES = %w[field_atlas nps].freeze

    def initialize(params)
      @params = params
    end

    def call
      results = []
      statuses = []

      if sources.include?("field_atlas")
        results.concat(canonical_results)
        statuses << { source: "field_atlas", status: "ok", freshness: "canonical" }
      end

      if sources.include?("nps")
        stored_records = stored_nps_records
        live = Sources::Nps::Adapter.new.search(query: query, limit: limit, types: types)
        statuses << live.fetch(:status)

        live_records = persist_live_records(live.fetch(:candidates))
        source_records = live_records.presence || stored_records
        results.concat(source_records.map { |record| record.to_search_result(freshness: live_records.present? ? "live_query" : "stored") })
      end

      filtered = dedupe_results(filter_results(results)).first(limit)
      {
        results: filtered,
        source_statuses: statuses,
        partial: statuses.any? { |status| %w[failed missing_key].include?(status.fetch(:status)) }
      }
    end

    private

    attr_reader :params

    def canonical_results
      scope = Place.all
      scope = scope.where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query)}%") if query.present?
      scope.limit(limit).map do |place|
        {
          id: "place:#{place.id}",
          result_type: "canonical_place",
          canonical_place_id: place.id,
          source: "field_atlas",
          source_id: nil,
          name: place.name,
          subtitle: "Field Atlas",
          category: place.primary_category || place.kind,
          geometry_type: place.centroid.present? ? "point" : nil,
          coordinate: coordinate_from_point(place.centroid),
          source_freshness: { mode: "canonical", fetched_at: place.updated_at.iso8601 }
        }.compact
      end
    end

    def stored_nps_records
      SourceRecord.where(provider: "nps").with_query(query).order(fetched_at: :desc).limit(limit)
    end

    def persist_live_records(candidates)
      return [] if candidates.blank?

      dataset = SourceDataset.find_or_create_by!(provider: "nps", name: "National Park Service") do |source_dataset|
        source_dataset.source_url = "https://developer.nps.gov/api/v1"
        source_dataset.freshness_mode = "live_query"
        source_dataset.status = "active"
      end
      upsert = SourceRecordUpsert.new(dataset: dataset)
      candidates.map { |candidate| upsert.call(candidate) }
    end

    def filter_results(results)
      results.select do |result|
        coordinate = result[:coordinate] || result["coordinate"]
        inside_bbox?(coordinate) && inside_radius?(coordinate)
      end
    end

    def dedupe_results(results)
      seen_canonical_place_ids = Set.new
      seen_source_keys = Set.new

      results.each_with_object([]) do |result, unique_results|
        canonical_place_id = result[:canonical_place_id] || result["canonical_place_id"]
        if canonical_place_id.present?
          next if seen_canonical_place_ids.include?(canonical_place_id)

          seen_canonical_place_ids << canonical_place_id
        else
          source_key = [ result[:source] || result["source"], result[:source_id] || result["source_id"] ]
          next if seen_source_keys.include?(source_key)

          seen_source_keys << source_key
        end

        unique_results << result
      end
    end

    def inside_bbox?(coordinate)
      return true if bbox.blank?
      return false if coordinate.blank?

      lat = coordinate[:lat] || coordinate["lat"]
      lng = coordinate[:lng] || coordinate["lng"]
      min_lng, min_lat, max_lng, max_lat = bbox
      lng.to_f.between?(min_lng, max_lng) && lat.to_f.between?(min_lat, max_lat)
    end

    def inside_radius?(coordinate)
      return true if center.blank? || radius_meters.blank?
      return false if coordinate.blank?

      lat = coordinate[:lat] || coordinate["lat"]
      lng = coordinate[:lng] || coordinate["lng"]
      Places::Geo.distance_meters(lat.to_f, lng.to_f, center.fetch(:lat), center.fetch(:lng)) <= radius_meters
    end

    def coordinate_from_point(point)
      return if point.blank?

      { lat: point.y, lng: point.x }
    end

    def query
      @query ||= params[:q].presence || params[:query].presence
    end

    def sources
      @sources ||= split_param(params[:sources]).presence || DEFAULT_SOURCES
    end

    def types
      @types ||= split_param(params[:types]).presence || Sources::Nps::Adapter::DEFAULT_TYPES
    end

    def limit
      raw_limit = params[:limit].presence || DEFAULT_LIMIT
      @limit ||= [ [ raw_limit.to_i, 1 ].max, 25 ].min
      @limit
    end

    def bbox
      @bbox ||= split_param(params[:bbox]).map(&:to_f) if params[:bbox].present?
    end

    def center
      return @center if defined?(@center)

      @center = if params[:center_lat].present? && params[:center_lng].present?
        { lat: params[:center_lat].to_f, lng: params[:center_lng].to_f }
      end
    end

    def radius_meters
      @radius_meters ||= params[:radius_meters].presence&.to_f
    end

    def split_param(value)
      value.to_s.split(",").map(&:strip).reject(&:blank?)
    end
  end
end
