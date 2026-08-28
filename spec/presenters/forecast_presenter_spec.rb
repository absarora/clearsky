# spec/presenters/forecast_presenter_spec.rb
#
# ForecastPresenter wraps a Forecast value object and exposes
# display-ready strings for the view layer.
#
# Keeps formatting logic out of views and helpers — views call
# presenter methods and never format data directly.

require "spec_helper"
require "date"
require_relative "../../app/value_objects/location"
require_relative "../../app/value_objects/forecast/day"
require_relative "../../app/value_objects/forecast"
require_relative "../../app/value_objects/forecast/null_forecast"
require_relative "../../app/presenters/forecast_presenter"

RSpec.describe Clearsky::ForecastPresenter do
  let(:location) do
    Clearsky::Location.new(zip: "93721", city: "Fresno", region: "California")
  end

  let(:forecast_days) do
    [
      Clearsky::Forecast::Day.new(
        date:           Date.new(2026, 8, 28),
        high_temp_f:    93.0,
        low_temp_f:     70.7,
        condition:      "Sunny",
        chance_of_rain: 0
      ),
      Clearsky::Forecast::Day.new(
        date:           Date.new(2026, 8, 29),
        high_temp_f:    88.0,
        low_temp_f:     68.0,
        condition:      "Partly Cloudy",
        chance_of_rain: 20
      )
    ]
  end

  let(:forecast) do
    Clearsky::Forecast.new(
      location:       location,
      current_temp_f: 72.9,
      feels_like_f:   66.7,
      condition:      "Patchy rain nearby",
      humidity:       42,
      wind_mph:       10.5,
      high_temp_f:    93.0,
      low_temp_f:     70.7,
      uv_index:       5.0,
      forecast_days:  forecast_days,
      cached:         false
    )
  end

  subject(:presenter) { described_class.new(forecast) }

  # ─── Temperature Formatting ──────────────────────────────────────────────

  describe "#current_temperature" do
    it "formats the current temperature with a degree symbol" do
      expect(presenter.current_temperature).to eq("72.9°F")
    end
  end

  describe "#feels_like" do
    it "formats the feels like temperature with a degree symbol" do
      expect(presenter.feels_like).to eq("66.7°F")
    end
  end

  describe "#high_temperature" do
    it "formats the high temperature with a degree symbol" do
      expect(presenter.high_temperature).to eq("93.0°F")
    end
  end

  describe "#low_temperature" do
    it "formats the low temperature with a degree symbol" do
      expect(presenter.low_temperature).to eq("70.7°F")
    end
  end

  # ─── Location ────────────────────────────────────────────────────────────

  describe "#location_name" do
    it "returns city and region" do
      expect(presenter.location_name).to eq("Fresno, California")
    end
  end

  # ─── Cache Indicator ─────────────────────────────────────────────────────

  describe "#cached_indicator" do
    context "when the forecast is from cache" do
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
          cached:         true
        )
      end

      it "returns the cached label" do
        expect(presenter.cached_indicator).to eq("Cached")
      end
    end

    context "when the forecast is live" do
      it "returns nil" do
        expect(presenter.cached_indicator).to be_nil
      end
    end
  end

  # ─── Extended Forecast ───────────────────────────────────────────────────

  describe "#forecast_days" do
    it "returns the forecast days from the forecast" do
      expect(presenter.forecast_days).to eq(forecast_days)
    end
  end

  describe "#format_day_temperature" do
    it "formats high and low temperatures for a forecast day" do
      day = forecast_days.first
      expect(presenter.format_day_temperature(day)).to eq("70.7°F / 93.0°F")
    end
  end

  describe "#format_day_date" do
    it "formats the date as abbreviated weekday and month/day" do
      day = forecast_days.first
      expect(presenter.format_day_date(day)).to eq("Fri, Aug 28")
    end
  end

  # ─── NullForecast ────────────────────────────────────────────────────────

  describe "with a NullForecast" do
    subject(:presenter) { described_class.new(Clearsky::Forecast::NullForecast.new) }

    it "returns a placeholder for current temperature" do
      expect(presenter.current_temperature).to eq("--°F")
    end

    it "returns an empty array for forecast days" do
      expect(presenter.forecast_days).to eq([])
    end

    it "returns nil for cached indicator" do
      expect(presenter.cached_indicator).to be_nil
    end
  end
end
