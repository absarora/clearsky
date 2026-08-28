# spec/services/forecast_service_spec.rb
#
# ForecastService orchestrates the weather provider and cache layer.
# It accepts a zip code, checks the cache first, and falls back to a
# live API call if no cached result exists.
#
# The weather provider is injected so specs can use a test double
# without making real HTTP calls.

require "rails_helper"
require_relative "../../app/services/forecast_service"
require_relative "../../app/value_objects/location"
require_relative "../../app/value_objects/forecast"
require_relative "../../app/value_objects/forecast/day"
require_relative "../../app/value_objects/forecast/null_forecast"

RSpec.describe Clearsky::ForecastService do
  let(:location) do
    Clearsky::Location.new(zip: "93721", city: "Fresno", region: "California")
  end

  let(:forecast) do
    Clearsky::Forecast.new(
      location:       location,
      current_temp_f: 72.0,
      feels_like_f:   70.2,
      condition:      "Sunny",
      humidity:       45,
      wind_mph:       8.1,
      high_temp_f:    75.0,
      low_temp_f:     58.0,
      uv_index:       5.0,
      forecast_days:  [],
      cached:         false
    )
  end

  # Inject a test double for the weather provider so specs never hit the API.
  let(:weather_provider) { instance_double(Clearsky::Weather::WeatherApiProvider) }
  let(:zip) { "93721" }

  subject(:service) { described_class.new(weather_provider:) }

  before do
    # Clear cache between examples to prevent cross-test pollution.
    Rails.cache.clear
  end

  # ─── Cache Miss ──────────────────────────────────────────────────────────

  describe "#call on a cache miss" do
    before do
      allow(weather_provider).to receive(:fetch_forecast).with(zip:).and_return(forecast)
    end

    it "calls the weather provider" do
      service.call(zip:)
      expect(weather_provider).to have_received(:fetch_forecast).with(zip:)
    end

    it "returns a Forecast value object" do
      result = service.call(zip:)
      expect(result).to be_a(Clearsky::Forecast)
    end

    it "returns a forecast marked as not cached" do
      result = service.call(zip:)
      expect(result.cached?).to be(false)
    end

    it "writes the result to cache" do
      service.call(zip:)
      expect(Rails.cache.read("clearsky:forecast:v1:#{zip}")).not_to be_nil
    end
  end

  # ─── Cache Hit ───────────────────────────────────────────────────────────

  describe "#call on a cache hit" do
    before do
      # Stub the provider even though it should not be called — have_received
      # requires the method to be stubbed before asserting it was not invoked.
      allow(weather_provider).to receive(:fetch_forecast)

      # Pre-warm the cache with a forecast marked as not cached.
      # ForecastService should mark it as cached on retrieval.
      Rails.cache.write(
        "clearsky:forecast:v1:#{zip}",
        forecast,
        expires_in: 30.minutes
      )
    end

    it "does not call the weather provider" do
      service.call(zip:)
      expect(weather_provider).not_to have_received(:fetch_forecast)
    end

    it "returns a Forecast value object" do
      result = service.call(zip:)
      expect(result).to be_a(Clearsky::Forecast)
    end

    it "returns a forecast marked as cached" do
      result = service.call(zip:)
      expect(result.cached?).to be(true)
    end
  end

  # ─── API Failure ─────────────────────────────────────────────────────────

  describe "#call when the weather provider raises an error" do
    before do
      allow(weather_provider).to receive(:fetch_forecast)
        .and_raise(Clearsky::WeatherApiError, "API unavailable")
    end

    it "returns a NullForecast" do
      result = service.call(zip:)
      expect(result).to be_a(Clearsky::Forecast::NullForecast)
    end

    it "returns an invalid forecast" do
      result = service.call(zip:)
      expect(result.valid?).to be(false)
    end

    it "does not write to the cache" do
      service.call(zip:)
      expect(Rails.cache.read("clearsky:forecast:v1:#{zip}")).to be_nil
    end
  end
end
