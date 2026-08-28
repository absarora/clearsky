# app/services/forecast_service.rb
#
# Orchestrates the weather provider and cache layer for a given zip code.
#
# Checks the cache first. On a miss, delegates to the weather provider,
# caches the result, and returns it. On a cache hit, marks the forecast
# as cached before returning.
#
# The weather provider is injected to support testing and future provider
# substitution without modifying this class.
#
# Returns a Forecast on success, NullForecast on any provider failure.

require_relative "../errors/weather_api_error"
require_relative "../value_objects/forecast"
require_relative "../value_objects/forecast/null_forecast"
require_relative "weather/weather_api_provider"

class ForecastService
  # Cache key namespace and TTL. The v1 prefix allows cache invalidation
  # via namespace bump if the cached data structure changes.
  CACHE_KEY_PREFIX = "clearsky:forecast:v1"
  CACHE_TTL        = 30.minutes

  def initialize(weather_provider: Weather::WeatherApiProvider.new)
    @weather_provider = weather_provider
  end

  # Fetches the forecast for the given zip code, reading from cache when
  # available and writing to cache on a live API response.
  #
  # @param zip [String] US zip code
  # @return [Forecast, Forecast::NullForecast]
  def call(zip:)
    cached_result = Rails.cache.read(cache_key(zip))

    if cached_result
      mark_as_cached(cached_result)
    else
      fetch_and_cache(zip:)
    end
  end

  private

  # Fetches a live forecast and writes it to cache on success.
  # Returns NullForecast if the provider raises a WeatherApiError.
  def fetch_and_cache(zip:)
    forecast = @weather_provider.fetch_forecast(zip:)
    Rails.cache.write(cache_key(zip), forecast, expires_in: CACHE_TTL)
    forecast
  rescue WeatherApiError
    Forecast::NullForecast.new
  end

  # Returns a new Forecast with cached: true. Because Forecast is frozen,
  # we reconstruct it with the updated flag rather than mutating in place.
  def mark_as_cached(forecast)
    Forecast.new(
      location:       forecast.location,
      current_temp_f: forecast.current_temp_f,
      feels_like_f:   forecast.feels_like_f,
      condition:      forecast.condition,
      humidity:       forecast.humidity,
      wind_mph:       forecast.wind_mph,
      high_temp_f:    forecast.high_temp_f,
      low_temp_f:     forecast.low_temp_f,
      uv_index:       forecast.uv_index,
      forecast_days:  forecast.forecast_days,
      cached:         true
    )
  end

  def cache_key(zip)
    "#{CACHE_KEY_PREFIX}:#{zip}"
  end
end
