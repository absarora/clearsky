# spec/support/vcr.rb
#
# VCR records real HTTP interactions on the first run and replays them on
# subsequent runs. This keeps specs deterministic and fast without hitting
# live APIs in CI.
#
# Cassettes are stored in spec/fixtures/vcr_cassettes/.
# Commit cassettes to source control so CI never makes live API calls.

require 'vcr'

VCR.configure do |config|
  # Directory where recorded HTTP interactions (cassettes) are stored.
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'

  # Use WebMock as the HTTP stubbing backend.
  config.hook_into :webmock

  # Make VCR available in RSpec via the :vcr metadata tag.
  # Usage: it "fetches forecast", :vcr do ... end
  config.configure_rspec_metadata!

  # Scrub the WeatherAPI key from recorded cassettes so it is never
  # committed to source control, even in fixture files.
  config.filter_sensitive_data('<WEATHER_API_KEY>') do
    Rails.application.credentials.dig(:weather_api, :key)
  end

  # Record mode:
  # :none       — never record; fail if no cassette exists (CI-safe default)
  # :new_episodes — record missing interactions, replay existing ones
  # :all        — always re-record (useful when API responses change)
  config.default_cassette_options = { record: :none }
end
