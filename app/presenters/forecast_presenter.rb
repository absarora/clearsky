# app/presenters/forecast_presenter.rb
#
# Wraps a Forecast value object and exposes display-ready strings
# for the view layer. Views call presenter methods and never format
# data directly.
#
# Handles both Forecast and Forecast::NullForecast transparently —
# the view never needs to check which type it's dealing with.

class ForecastPresenter
  def initialize(forecast)
    @forecast = forecast
  end

  def current_temperature
    format_temp(@forecast.current_temp_f)
  end

  def feels_like
    format_temp(@forecast.feels_like_f)
  end

  def high_temperature
    format_temp(@forecast.high_temp_f)
  end

  def low_temperature
    format_temp(@forecast.low_temp_f)
  end

  def location_name
    "#{@forecast.location.city}, #{@forecast.location.region}"
  end

  def condition
    @forecast.condition
  end

  def humidity
    @forecast.humidity
  end

  def wind_mph
    @forecast.wind_mph
  end

  def uv_index
    @forecast.uv_index
  end

  def forecast_days
    @forecast.forecast_days
  end

  # Returns "Cached" when the result was served from cache, nil otherwise.
  # The view uses this to conditionally render the cache indicator badge.
  def cached_indicator
    "Cached" if @forecast.cached?
  end

  # Formats high/low temperatures for a single forecast day.
  def format_day_temperature(day)
    "#{format_temp(day.low_temp_f)} / #{format_temp(day.high_temp_f)}"
  end

  # Formats a forecast day date as abbreviated weekday and month/day.
  def format_day_date(day)
    day.date.strftime("%a, %b %-d")
  end

  private

  # Returns a placeholder when the value is nil (NullForecast),
  # otherwise formats with one decimal place and degree symbol.
  def format_temp(value)
    value.nil? ? "--°F" : "#{"%.1f" % value}°F"
  end
end
