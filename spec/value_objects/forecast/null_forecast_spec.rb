# spec/value_objects/forecast/null_forecast_spec.rb
#
# NullForecast is returned by ForecastService when geocoding or the weather
# API fails. It implements the same interface as Forecast but returns safe
# defaults, eliminating nil checks in the view layer.

require "spec_helper"
require_relative "../../../app/value_objects/forecast/null_forecast"

RSpec.describe Forecast::NullForecast do
  subject(:null_forecast) { described_class.new }

  # ─── Null Interface ──────────────────────────────────────────────────────
  #
  # Every attribute Forecast exposes must be present on NullForecast.
  # The view should never need to check which type it's dealing with.

  describe "null interface" do
    it { expect(null_forecast.current_temp_f).to be_nil }
    it { expect(null_forecast.feels_like_f).to be_nil }
    it { expect(null_forecast.condition).to be_nil }
    it { expect(null_forecast.humidity).to be_nil }
    it { expect(null_forecast.wind_mph).to be_nil }
    it { expect(null_forecast.high_temp_f).to be_nil }
    it { expect(null_forecast.low_temp_f).to be_nil }
    it { expect(null_forecast.uv_index).to be_nil }
    it { expect(null_forecast.forecast_days).to eq([]) }
    it { expect(null_forecast.cached).to be(false) }
  end

  # ─── Valid Flag ───────────────────────────────────────────────────────────
  #
  # valid? allows the controller and view to detect a failed forecast
  # without nil checks or type inspection.

  describe "#valid?" do
    it "returns false" do
      expect(null_forecast.valid?).to be(false)
    end
  end

  describe "#cached?" do
    it "returns false" do
      expect(null_forecast.cached?).to be(false)
    end
  end

  # ─── Immutability ────────────────────────────────────────────────────────

  describe "immutability" do
    it "is frozen after initialization" do
      expect(null_forecast).to be_frozen
    end
  end
end
