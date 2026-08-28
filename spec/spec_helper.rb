# spec/spec_helper.rb
#
# This file is loaded on every RSpec run. Keep it lightweight — heavy dependencies
# belong in rails_helper.rb or individual support files, not here.
#
# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

RSpec.configure do |config|
  # Use the expect syntax exclusively. The should syntax is deprecated.
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Verify that mocked methods actually exist on the real object.
  # Prevents specs from passing against an interface that has changed.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Run only specs tagged with :focus when any exist; run all otherwise.
  config.filter_run_when_matching :focus

  # Persists example pass/fail state to support --only-failures and --next-failure.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Disables monkey-patching (describe/it at the top level without RSpec prefix).
  config.disable_monkey_patching!

  # Use documentation formatter when running a single file.
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Run specs in random order to surface hidden order dependencies.
  config.order = :random

  # Allows reproduction of a specific random order via --seed.
  Kernel.srand config.seed
end
