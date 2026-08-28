# app/value_objects/forecast/null_forecast.rb
#
# Null Object implementation of Forecast. Returned by ForecastService when
# geocoding or the weather API fails. Implements the same interface as
# Forecast with safe defaults, eliminating nil checks in the view layer.
#
# The controller checks valid? to decide whether to render an error message.

module Clearsky
  class Forecast
    class NullForecast
      attr_reader :current_temp_f, :feels_like_f, :condition, :humidity,
                  :wind_mph, :high_temp_f, :low_temp_f, :uv_index,
                  :forecast_days, :cached

      def initialize
        @current_temp_f = nil
        @feels_like_f   = nil
        @condition      = nil
        @humidity       = nil
        @wind_mph       = nil
        @high_temp_f    = nil
        @low_temp_f     = nil
        @uv_index       = nil
        @forecast_days  = [].freeze
        @cached         = false
        freeze
      end

      def valid?
        false
      end

      def cached?
        false
      end
    end
  end
end
