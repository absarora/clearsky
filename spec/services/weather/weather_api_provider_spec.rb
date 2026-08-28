# spec/services/weather/weather_api_provider_spec.rb
#
# WeatherApiProvider is the concrete weather provider implementation.
# It communicates with WeatherAPI's forecast endpoint via Faraday and
# returns a Forecast value object.
#
# HTTP interactions are recorded via VCR on first run and replayed
# on subsequent runs — no live API calls in CI.

require "rails_helper"
require_relative "../../../app/services/weather/weather_api_provider"

RSpec.describe Clearsky::Weather::WeatherApiProvider do
  subject(:provider) { described_class.new }

  # A real zip code used for the VCR cassette recording.
  let(:zip) { "93721" }

  describe "#fetch_forecast" do
    context "with a valid zip code", :vcr do
      subject(:forecast) { provider.fetch_forecast(zip:) }

      it "returns a Forecast value object" do
        expect(forecast).to be_a(Clearsky::Forecast)
      end

      it "returns current temperature" do
        expect(forecast.current_temp_f).to be_a(Float)
      end

      it "returns feels like temperature" do
        expect(forecast.feels_like_f).to be_a(Float)
      end

      it "returns a condition string" do
        expect(forecast.condition).to be_a(String)
        expect(forecast.condition).not_to be_empty
      end

      it "returns humidity as an integer" do
        expect(forecast.humidity).to be_a(Integer)
      end

      it "returns wind speed" do
        expect(forecast.wind_mph).to be_a(Float)
      end

      it "returns today's high temperature" do
        expect(forecast.high_temp_f).to be_a(Float)
      end

      it "returns today's low temperature" do
        expect(forecast.low_temp_f).to be_a(Float)
      end

      it "returns a uv index" do
        expect(forecast.uv_index).to be_a(Float)
      end

      it "returns 7 days of extended forecast" do
        expect(forecast.forecast_days.length).to eq(7)
      end

      it "returns forecast days as Forecast::Day objects" do
        expect(forecast.forecast_days).to all(be_a(Clearsky::Forecast::Day))
      end

      it "returns a Location with the correct zip" do
        expect(forecast.location.zip).to eq(zip)
      end

      it "is not cached by default" do
        expect(forecast.cached?).to be(false)
      end
    end

    context "with an invalid zip code", :vcr do
      it "raises a WeatherApiError" do
        expect {
          provider.fetch_forecast(zip: "00000")
        }.to raise_error(Clearsky::WeatherApiError)
      end
    end

    context "when the API is unreachable" do
      before do
        stub_request(:get, /api.weatherapi.com/).to_timeout
      end

      it "raises a WeatherApiError" do
        expect {
          provider.fetch_forecast(zip:)
        }.to raise_error(Clearsky::WeatherApiError)
      end
    end
  end
end
