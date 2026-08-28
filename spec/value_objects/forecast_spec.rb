# spec/value_objects/forecast_spec.rb
#
# Forecast is the primary value object returned by ForecastService.
# It wraps the full WeatherAPI response and exposes a stable interface
# to the presenter and view, decoupling them from the API's JSON structure.

require "spec_helper"
require "date"
require_relative "../../app/value_objects/forecast/day"
require_relative "../../app/value_objects/forecast"

RSpec.describe Clearsky::Forecast do
  let(:forecast_day) do
    Clearsky::Forecast::Day.new(
      date:           Date.new(2025, 1, 15),
      high_temp_f:    75.0,
      low_temp_f:     58.0,
      condition:      "Sunny",
      chance_of_rain: 0
    )
  end

  let(:valid_attributes) do
    {
      current_temp_f: 72.0,
      feels_like_f:   70.2,
      condition:      "Sunny",
      humidity:       45,
      wind_mph:       8.1,
      high_temp_f:    75.0,
      low_temp_f:     58.0,
      uv_index:       5.0,
      forecast_days:  [forecast_day],
      cached:         false
    }
  end

  subject(:forecast) { described_class.new(**valid_attributes) }

  # ─── Attribute Access ────────────────────────────────────────────────────

  describe "attribute access" do
    it { expect(forecast.current_temp_f).to eq(72.0) }
    it { expect(forecast.feels_like_f).to eq(70.2) }
    it { expect(forecast.condition).to eq("Sunny") }
    it { expect(forecast.humidity).to eq(45) }
    it { expect(forecast.wind_mph).to eq(8.1) }
    it { expect(forecast.high_temp_f).to eq(75.0) }
    it { expect(forecast.low_temp_f).to eq(58.0) }
    it { expect(forecast.uv_index).to eq(5.0) }
    it { expect(forecast.forecast_days).to eq([forecast_day]) }
    it { expect(forecast.cached).to eq(false) }
  end

  # ─── Cache Flag ──────────────────────────────────────────────────────────

  describe "#cached?" do
    it "returns false when not served from cache" do
      expect(forecast.cached?).to be(false)
    end

    it "returns true when served from cache" do
      cached_forecast = described_class.new(**valid_attributes.merge(cached: true))
      expect(cached_forecast.cached?).to be(true)
    end
  end

  # ─── Forecast Days ───────────────────────────────────────────────────────

  describe "#forecast_days" do
    it "returns an array of Forecast::Day objects" do
      expect(forecast.forecast_days).to all(be_a(Clearsky::Forecast::Day))
    end

    it "is frozen" do
      expect(forecast.forecast_days).to be_frozen
    end
  end

  # ─── Immutability ────────────────────────────────────────────────────────

  describe "immutability" do
    it "is frozen after initialization" do
      expect(forecast).to be_frozen
    end
  end

  # ─── Validation ──────────────────────────────────────────────────────────

  describe "validation" do
    it "raises ArgumentError when current_temp_f is missing" do
      expect { described_class.new(**valid_attributes.except(:current_temp_f)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when condition is missing" do
      expect { described_class.new(**valid_attributes.except(:condition)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when forecast_days is missing" do
      expect { described_class.new(**valid_attributes.except(:forecast_days)) }.to raise_error(ArgumentError)
    end
  end
end
