# spec/value_objects/location_spec.rb
#
# Location is an immutable value object representing a resolved geographic
# location. Produced by Weather::WeatherApiProvider from the API response
# location block, and used as the cache key source (zip).

require "spec_helper"
require_relative "../../app/value_objects/location"

RSpec.describe Location do
  let(:valid_attributes) do
    {
      zip:    "93721",
      city:   "Fresno",
      region: "California"
    }
  end

  subject(:location) { described_class.new(**valid_attributes) }

  describe "attribute access" do
    it { expect(location.zip).to eq("93721") }
    it { expect(location.city).to eq("Fresno") }
    it { expect(location.region).to eq("California") }
  end

  describe "immutability" do
    it "is frozen after initialization" do
      expect(location).to be_frozen
    end

    it "raises FrozenError when attempting to modify an attribute" do
      expect { location.instance_variable_set(:@zip, "00000") }.to raise_error(FrozenError)
    end
  end

  describe "value equality" do
    it "is equal to another Location with the same attributes" do
      expect(location).to eq(described_class.new(**valid_attributes))
    end

    it "is not equal to a Location with a different zip" do
      other = described_class.new(**valid_attributes.merge(zip: "94102"))
      expect(location).not_to eq(other)
    end
  end

  describe "validation" do
    it "raises ArgumentError when zip is missing" do
      expect { described_class.new(**valid_attributes.except(:zip)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when city is missing" do
      expect { described_class.new(**valid_attributes.except(:city)) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when region is missing" do
      expect { described_class.new(**valid_attributes.except(:region)) }.to raise_error(ArgumentError)
    end
  end

  describe "#to_s" do
    it "returns a human-readable location string" do
      expect(location.to_s).to eq("Fresno, California 93721")
    end
  end
end
