source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem 'sidekiq'

group :test do
  gem 'database_cleaner-active_record'
  gem 'null-logger', require: 'null_logger'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'timecop'
end
