# frozen_string_literal: true

require 'bundler/setup'
require 'ice_age/freeze' # freeze ENV
require 'null_logger'
require 'pry'
require 'simplecov'


SimpleCov.start unless SimpleCov.running

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # allow 'fit' examples
  config.filter_run_when_matching :focus

  config.around(:each) do |example|
    # only let Timecop operate in blocks
    Timecop.safe_mode = true

    # Freeze time by default
    Timecop.freeze do
      example.run
    end
  end

  # remove stdout logging when running tests
  Sidekiq.logger = NullLogger.new

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
end
