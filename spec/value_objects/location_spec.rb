# spec/value_objects/location_spec.rb
#
# Location is an immutable value object representing a resolved geographic
# location. It is produced by the geocoder and consumed by the weather
# provider and cache layer.
#
# Key behaviors under test:
#   - Accepts and exposes all expected attributes
#   - Is frozen (immutable) after initialization
#   - Equality is based on value, not object identity
#   - Rejects construction when required attributes are missing

require "spec_helper"
require "ostruct"

# Explicitly require the class under test. Value object specs use spec_helper
# (not rails_helper) since they are pure Ruby with no Rails dependencies.
require_relative "../../app/value_objects/location"

RSpec.describe Clearsky::Location do
  # Valid attribute set used as a baseline across examples.
  let(:valid_attributes) do
    {
      lat:     36.7378,
      lon:     -119.7871,
      zip:     "93721",
      city:    "Fresno",
      region:  "California",
      country: "USA"
    }
  end

  subject(:location) { described_class.new(**valid_attributes) }

  # ─── Attribute Access ────────────────────────────────────────────────────

  describe "attribute access" do
    it "exposes lat" do
      expect(location.lat).to eq(36.7378)
    end

    it "exposes lon" do
      expect(location.lon).to eq(-119.7871)
    end

    it "exposes zip" do
      expect(location.zip).to eq("93721")
    end

    it "exposes city" do
      expect(location.city).to eq("Fresno")
    end

    it "exposes region" do
      expect(location.region).to eq("California")
    end

    it "exposes country" do
      expect(location.country).to eq("USA")
    end
  end

  # ─── Immutability ────────────────────────────────────────────────────────

  describe "immutability" do
    it "is frozen after initialization" do
      expect(location).to be_frozen
    end

    it "raises FrozenError when attempting to modify an attribute" do
      expect { location.instance_variable_set(:@zip, "00000") }.to raise_error(FrozenError)
    end
  end

  # ─── Value Equality ──────────────────────────────────────────────────────

  describe "value equality" do
    it "is equal to another Location with the same attributes" do
      other = described_class.new(**valid_attributes)
      expect(location).to eq(other)
    end

    it "is not equal to a Location with a different zip" do
      other = described_class.new(**valid_attributes.merge(zip: "94102"))
      expect(location).not_to eq(other)
    end

    it "is not equal to a Location with different coordinates" do
      other = described_class.new(**valid_attributes.merge(lat: 37.7749, lon: -122.4194))
      expect(location).not_to eq(other)
    end
  end

  # ─── Validation ──────────────────────────────────────────────────────────

  describe "validation" do
    it "raises ArgumentError when lat is missing" do
      expect {
        described_class.new(**valid_attributes.except(:lat))
      }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when lon is missing" do
      expect {
        described_class.new(**valid_attributes.except(:lon))
      }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when zip is missing" do
      expect {
        described_class.new(**valid_attributes.except(:zip))
      }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when city is missing" do
      expect {
        described_class.new(**valid_attributes.except(:city))
      }.to raise_error(ArgumentError)
    end
  end
end
