# app/value_objects/forecast/day.rb
#
# Immutable value object representing a single day in the extended forecast.
# Nested under Forecast and produced by Weather::WeatherApiProvider.

module Clearsky
  class Forecast
    class Day
      attr_reader :date, :high_temp_f, :low_temp_f, :condition, :chance_of_rain

      def initialize(date:, high_temp_f:, low_temp_f:, condition:, chance_of_rain:)
        @date           = date
        @high_temp_f    = high_temp_f
        @low_temp_f     = low_temp_f
        @condition      = condition
        @chance_of_rain = chance_of_rain
        freeze
      end

      # Value equality — two Days with identical attributes are the same day.
      def ==(other)
        other.is_a?(self.class)   &&
          date           == other.date           &&
          high_temp_f    == other.high_temp_f    &&
          low_temp_f     == other.low_temp_f     &&
          condition      == other.condition      &&
          chance_of_rain == other.chance_of_rain
      end

      # eql? and hash must be consistent with == for correct Hash/Set behavior.
      alias eql? ==

      def hash
        [date, high_temp_f, low_temp_f, condition, chance_of_rain].hash
      end

      def to_s
        "#{date}: #{condition}, #{low_temp_f}°F – #{high_temp_f}°F"
      end
    end
  end
end
