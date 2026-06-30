module Sources
  module Nps
    class BoundaryImporter
      Result = Data.define(:checked, :updated, :missing, :failed)

      def initialize(client: Client.new)
        @client = client
      end

      def call
        stats = {
          checked: 0,
          updated: 0,
          missing: [],
          failed: []
        }

        nps_park_units.find_each do |park_unit|
          import_boundary(park_unit, stats)
        end

        Result.new(
          checked: stats.fetch(:checked),
          updated: stats.fetch(:updated),
          missing: stats.fetch(:missing),
          failed: stats.fetch(:failed)
        )
      end

      private

      attr_reader :client

      def nps_park_units
        ParkUnit.includes(:place).where(agency: "nps").where.not(official_code: [ nil, "" ])
      end

      def import_boundary(park_unit, stats)
        stats[:checked] += 1
        response = client.get(boundary_path(park_unit.official_code))

        unless response.success?
          stats.fetch(:failed) << failure_payload(park_unit, "http_#{response.status}")
          return
        end

        geometry = geometry_payload(response.body)
        if geometry.blank?
          stats.fetch(:missing) << {
            place_id: park_unit.place_id,
            park_code: park_unit.official_code,
            reason: "missing_geometry"
          }
          return
        end

        update_place_geometry(park_unit.place, geometry)
        stats[:updated] += 1
      rescue ActiveRecord::ActiveRecordError, JSON::GeneratorError => error
        stats.fetch(:failed) << failure_payload(park_unit, error.message)
      end

      def boundary_path(park_code)
        "/mapdata/parkboundaries/#{park_code}"
      end

      def geometry_payload(body)
        return if body.blank?

        case body["type"]
        when "FeatureCollection"
          Array(body["features"]).filter_map { |feature| feature["geometry"].presence }.first
        when "Feature"
          body["geometry"]
        else
          body if body["coordinates"].present?
        end
      end

      def update_place_geometry(place, geometry)
        updates = ActiveRecord::Base.sanitize_sql_array(
          [
            "geometry = ST_SetSRID(ST_GeomFromGeoJSON(?), 4326)::geography, updated_at = ?",
            ::JSON.generate(geometry),
            Time.current
          ]
        )
        Place.where(id: place.id).update_all(updates)
      end

      def failure_payload(park_unit, reason)
        {
          place_id: park_unit.place_id,
          park_code: park_unit.official_code,
          reason: reason
        }
      end
    end
  end
end
