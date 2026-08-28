# app/value_objects/location.rb
#
# Immutable value object representing a resolved geographic location.
# Produced by Geocoding::WeatherApiGeocoder, consumed by the weather
# provider and cache layer (zip is the cache key).

module Clearsky
  class Location
    attr_reader :lat, :lon, :zip, :city, :region, :country

    def initialize(lat:, lon:, zip:, city:, region:, country:)
      @lat     = lat
      @lon     = lon
      @zip     = zip
      @city    = city
      @region  = region
      @country = country
      freeze
    end

    # Value equality — two Locations with identical attributes are the same location.
    def ==(other)
      other.is_a?(self.class) &&
        lat     == other.lat     &&
        lon     == other.lon     &&
        zip     == other.zip     &&
        city    == other.city    &&
        region  == other.region  &&
        country == other.country
    end

    # eql? and hash must be consistent with == for correct Hash/Set behavior.
    alias eql? ==

    def hash
      [lat, lon, zip, city, region, country].hash
    end

    def to_s
      "#{city}, #{region} #{zip}"
    end

    def inspect
      "#<Clearsky::Location #{to_s} (#{lat}, #{lon})>"
    end
  end
end
