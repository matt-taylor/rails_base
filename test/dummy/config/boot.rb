# Ruby 3.2+ with ActiveSupport 6.1: Logger is not loaded before ActiveSupport references
# Logger::Severity (NameError: uninitialized constant ...::Logger). Load stdlib explicitly.
require 'logger'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../Gemfile', __dir__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)
