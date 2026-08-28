# app/services/weather/weather_api_provider.rb
#
# Concrete weather provider implementation using WeatherAPI.com.
# Accepts a US zip code, fetches current conditions and a 7-day
# extended forecast, and returns a Forecast value object.
#
# Faraday is configured with explicit timeouts and retry logic to
# ensure a slow or flaky API never hangs a Puma thread.
#
# Raises WeatherApiError on any API or network failure
# so callers can handle it without rescuing StandardError broadly.

require "faraday"
require "faraday/retry"
require_relative "../../errors/weather_api_error"
require_relative "../../value_objects/location"
require_relative "../../value_objects/forecast"
require_relative "../../value_objects/forecast/day"

module Weather
  class WeatherApiProvider
    BASE_URL  = "https://api.weatherapi.com/v1"
    DAYS      = 7

    def initialize
      @api_key = Rails.application.credentials.dig(:weather_api, :key)
    end

    # Fetches current conditions and extended forecast for the given zip code.
    #
    # @param zip [String] US zip code provided by the user
    # @return [Forecast]
    # @raise [WeatherApiError] on API error or network failure
    def fetch_forecast(zip:)
      response = client.get("forecast.json") do |req|
        req.params[:key]     = @api_key
        req.params[:q]       = zip
        req.params[:days]    = DAYS
        req.params[:aqi]     = "no"
        req.params[:alerts]  = "no"
      end

      handle_response(response, zip:)
    rescue Faraday::Error => e
      raise WeatherApiError, "WeatherAPI request failed: #{e.message}"
    end

    private

    # Faraday client configured with timeouts and retry on transient failures.
    # Retry is limited to GET requests only and never retries on 4xx responses.
    def client
      @client ||= Faraday.new(url: BASE_URL) do |f|
        f.request  :retry, max: 2, interval: 0.5, backoff_factor: 2,
                           retry_statuses: [500, 502, 503, 504],
                           methods: [:get]
        f.response :raise_error
        f.adapter  Faraday.default_adapter
        f.options.open_timeout = 2
        f.options.timeout      = 5
      end
    end

    # Parses the raw API response into a Forecast value object.
    # Raises WeatherApiError if the response shape is unexpected.
    def handle_response(response, zip:)
      body = JSON.parse(response.body)
      build_forecast(body, zip:)
    rescue JSON::ParserError
      raise WeatherApiError, "WeatherAPI returned an unparseable response"
    rescue KeyError, TypeError => e
      raise WeatherApiError, "WeatherAPI response missing expected fields: #{e.message}"
    end

    def build_forecast(body, zip:)
      current     = body.fetch("current")
      today       = body.fetch("forecast").fetch("forecastday").first.fetch("day")
      location    = build_location(body.fetch("location"), zip:)
      days        = build_forecast_days(body.fetch("forecast").fetch("forecastday"))

      Forecast.new(
        location:       location,
        current_temp_f: current.fetch("temp_f").to_f,
        feels_like_f:   current.fetch("feelslike_f").to_f,
        condition:      current.fetch("condition").fetch("text"),
        humidity:       current.fetch("humidity").to_i,
        wind_mph:       current.fetch("wind_mph").to_f,
        high_temp_f:    today.fetch("maxtemp_f").to_f,
        low_temp_f:     today.fetch("mintemp_f").to_f,
        uv_index:       current.fetch("uv").to_f,
        forecast_days:  days
      )
    end

    def build_location(location_data, zip:)
      Location.new(
        zip:    zip,
        city:   location_data.fetch("name"),
        region: location_data.fetch("region")
      )
    end

    def build_forecast_days(forecastdays)
      forecastdays.map do |fd|
        day = fd.fetch("day")
        Forecast::Day.new(
          date:           Date.parse(fd.fetch("date")),
          high_temp_f:    day.fetch("maxtemp_f").to_f,
          low_temp_f:     day.fetch("mintemp_f").to_f,
          condition:      day.fetch("condition").fetch("text"),
          chance_of_rain: day.fetch("daily_chance_of_rain").to_i
        )
      end
    end
  end
end
