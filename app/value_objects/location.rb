# app/value_objects/location.rb
#
# Immutable value object representing a resolved geographic location.
# Produced from the location block in WeatherAPI's response.
# The zip code is used as the forecast cache key.

module Clearsky
  class Location
    attr_reader :zip, :city, :region

    def initialize(zip:, city:, region:)
      @zip    = zip
      @city   = city
      @region = region
      freeze
    end

    # Value equality — two Locations with identical attributes are the same location.
    def ==(other)
      other.is_a?(self.class) &&
        zip    == other.zip    &&
        city   == other.city   &&
        region == other.region
    end

    # eql? and hash must be consistent with == for correct Hash/Set behavior.
    alias eql? ==

    def hash
      [zip, city, region].hash
    end

    def to_s
      "#{city}, #{region} #{zip}"
    end

    def inspect
      "#<Clearsky::Location #{to_s}>" # rubocop:disable Lint/RedundantStringCoercion
    end
  end
end
