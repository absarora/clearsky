# spec/rails_helper.rb
#
# Required by specs that need the Rails environment (controllers, requests, etc.).
# Pure Ruby specs (value objects, service objects) should require only 'spec_helper'
# to keep boot time fast.

require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Abort if accidentally running against production.
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'webmock/rspec'

# Auto-require all support files. These define shared contexts, helpers, and
# custom matchers used across the suite.
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensure test database schema is current. Remove if not using ActiveRecord.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]

  # Wrap each example in a transaction, rolled back after the example completes.
  config.use_transactional_fixtures = true

  # Infer spec type from file location (e.g. spec/controllers → type: :controller).
  config.infer_spec_type_from_file_location!

  # Filter Rails gem internals from backtraces for cleaner failure output.
  config.filter_rails_from_backtrace!
end

# Disable all external HTTP requests in the test suite.
# Any spec that needs HTTP must stub it explicitly via WebMock or VCR.
WebMock.disable_net_connect!(allow_localhost: true)
