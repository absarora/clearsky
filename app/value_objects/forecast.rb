# app/value_objects/forecast.rb
#
# Immutable value object wrapping the full WeatherAPI response.
# Exposes a stable interface to ForecastPresenter and the view layer,
# decoupling them from the API's JSON structure.
#
# If WeatherAPI's response shape changes, only this class needs updating.
#
# The `cached` flag is set by ForecastService — not the API — to indicate
# whether the result was served from cache or a live request.

require_relative "forecast/day"

module Clearsky
  class Forecast
    attr_reader :current_temp_f, :feels_like_f, :condition, :humidity,
                :wind_mph, :high_temp_f, :low_temp_f, :uv_index,
                :forecast_days, :cached

    def initialize(
      current_temp_f:,
      feels_like_f:,
      condition:,
      humidity:,
      wind_mph:,
      high_temp_f:,
      low_temp_f:,
      uv_index:,
      forecast_days:,
      cached: false
    )
      @current_temp_f = current_temp_f
      @feels_like_f   = feels_like_f
      @condition      = condition
      @humidity       = humidity
      @wind_mph       = wind_mph
      @high_temp_f    = high_temp_f
      @low_temp_f     = low_temp_f
      @uv_index       = uv_index
      @forecast_days  = forecast_days.freeze
      @cached         = cached
      freeze
    end

    # Convenience predicate for the presenter and view cache indicator.
    def cached?
      cached == true
    end
  end
end
