module Places
  module Geo
    EARTH_RADIUS_METERS = 6_371_000.0

    module_function

    def point(lng:, lat:)
      factory.point(lng, lat)
    end

    def distance_meters(lat_a, lng_a, lat_b, lng_b)
      delta_lat = radians(lat_b - lat_a)
      delta_lng = radians(lng_b - lng_a)
      a = Math.sin(delta_lat / 2)**2 +
        Math.cos(radians(lat_a)) * Math.cos(radians(lat_b)) *
          Math.sin(delta_lng / 2)**2
      2 * EARTH_RADIUS_METERS * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    end

    def factory
      @factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
    end

    def radians(degrees)
      degrees * Math::PI / 180.0
    end
  end
end
