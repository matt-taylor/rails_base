source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

# Use custom ruby version or whatever is already defined
ruby ENV["CUSTOM_RUBY_VERSION"] || RUBY_VERSION

gem "rails", ENV.fetch("BUNDLER_RAILS_VERSION", "~> 6")

gem "sidekiq"
gem "webrick" # needed to run with ruby 3

group :test do
  gem "database_cleaner-active_record"
  gem "factory_bot"
  gem "faker"
  gem "null-logger", require: "null_logger"
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "rspec_junit_formatter"
  gem "simplecov", require: false
  gem "timecop"
end
