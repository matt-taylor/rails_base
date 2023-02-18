source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem 'rails', ENV.fetch("BUNDLER_RAILS_VERSION", '~> 7')
gem "pry"
gem 'sidekiq'
gem 'webrick' # needed to run with ruby 3

gem 'net-smtp'
gem 'net-imap'
gem 'net-pop'

group :test do
  gem 'database_cleaner-active_record'
  gem 'null-logger', require: 'null_logger'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'timecop'
end
