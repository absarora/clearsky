# spec/value_objects/forecast/day_spec.rb
#
# Forecast::Day represents a single day in the extended forecast.
# It is an immutable value object nested within Forecast.

require "spec_helper"
require_relative "../../../app/value_objects/forecast/day"

RSpec.describe Clearsky::Forecast::Day do
  let(:valid_attributes) do
    {
      date:            Date.new(2025, 1, 15),
      high_temp_f:     75.0,
      low_temp_f:      58.0,
      condition:       "Sunny",
      chance_of_rain:  0
    }
  end

  subject(:day) { described_class.new(**valid_attributes) }

  describe "attribute access" do
    it { expect(day.date).to eq(Date.new(2025, 1, 15)) }
    it { expect(day.high_temp_f).to eq(75.0) }
    it { expect(day.low_temp_f).to eq(58.0) }
    it { expect(day.condition).to eq("Sunny") }
    it { expect(day.chance_of_rain).to eq(0) }
  end

  describe "immutability" do
    it "is frozen after initialization" do
      expect(day).to be_frozen
    end
  end

  describe "value equality" do
    it "is equal to another Day with the same attributes" do
      expect(day).to eq(described_class.new(**valid_attributes))
    end

    it "is not equal to a Day with a different date" do
      other = described_class.new(**valid_attributes.merge(date: Date.new(2025, 1, 16)))
      expect(day).not_to eq(other)
    end

    it "is not equal to a Day with different temperatures" do
      other = described_class.new(**valid_attributes.merge(high_temp_f: 90.0))
      expect(day).not_to eq(other)
    end
  end

  describe "validation" do
    it "raises ArgumentError when date is missing" do
      expect { described_class.new(**valid_attributes.except(:date)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when high_temp_f is missing" do
      expect { described_class.new(**valid_attributes.except(:high_temp_f)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when low_temp_f is missing" do
      expect { described_class.new(**valid_attributes.except(:low_temp_f)) }.to raise_error(ArgumentError)
    end
  end
end
