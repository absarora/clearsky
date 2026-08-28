# spec/requests/forecasts_spec.rb
#
# Request specs for ForecastsController. Tests the full HTTP stack
# including routing, parameter handling, and response codes.
#
# ForecastService is stubbed so these specs remain fast and isolated
# from external API calls.

require "rails_helper"
require_relative "../../app/value_objects/location"
require_relative "../../app/value_objects/forecast/day"
require_relative "../../app/value_objects/forecast"
require_relative "../../app/value_objects/forecast/null_forecast"
require_relative "../../app/services/forecast_service"

RSpec.describe "Forecasts", type: :request do
  let(:location) do
    Clearsky::Location.new(zip: "93721", city: "Fresno", region: "California")
  end

  let(:forecast) do
    Clearsky::Forecast.new(
      location:       location,
      current_temp_f: 72.9,
      feels_like_f:   66.7,
      condition:      "Sunny",
      humidity:       42,
      wind_mph:       10.5,
      high_temp_f:    93.0,
      low_temp_f:     70.7,
      uv_index:       5.0,
      forecast_days:  [],
      cached:         false
    )
  end

  let(:forecast_service) { instance_double(Clearsky::ForecastService) }

  before do
    allow(Clearsky::ForecastService).to receive(:new).and_return(forecast_service)
  end

  # ─── GET / ───────────────────────────────────────────────────────────────

  describe "GET /" do
    it "returns 200 OK" do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ─── GET /forecast ───────────────────────────────────────────────────────

  describe "GET /forecast" do
    context "with a valid zip code" do
      before do
        allow(forecast_service).to receive(:call).with(zip: "93721").and_return(forecast)
      end

      it "returns 200 OK" do
        get forecast_path, params: { zip: "93721" }
        expect(response).to have_http_status(:ok)
      end

      it "calls ForecastService with the zip code" do
        get forecast_path, params: { zip: "93721" }
        expect(forecast_service).to have_received(:call).with(zip: "93721")
      end
    end

    context "with a blank zip code" do
      it "redirects to root with an error flash" do
        get forecast_path, params: { zip: "" }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when ForecastService returns a NullForecast" do
      before do
        allow(forecast_service).to receive(:call).and_return(
          Clearsky::Forecast::NullForecast.new
        )
      end

      it "returns 200 OK" do
        get forecast_path, params: { zip: "93721" }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─── GET /health ─────────────────────────────────────────────────────────

  describe "GET /health" do
    it "returns 200 OK" do
      get "/health"
      expect(response).to have_http_status(:ok)
    end
  end
end
