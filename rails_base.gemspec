$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rails_base/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rails_base"
  spec.version     = RailsBase::VERSION
  spec.authors     = ["Matt Taylor"]
  spec.email       = ["mattius.taylor@gmail.com"]
  spec.summary     = "Rails engine that takes care of the stuff you dont want to!"
  spec.description = "Rails Engine that handles authentication, admin, 2fa, audit tracking, with insane configuration abilites"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails"
  spec.add_dependency 'mysql2'
  spec.add_dependency 'sass-rails'
  spec.add_dependency 'uglifier'
  spec.add_dependency 'turbolinks'
  spec.add_dependency 'coffee-rails'
  spec.add_dependency 'jquery-rails', '~> 4.3', '>= 4.3.3'
  spec.add_dependency 'rails-ujs', '~> 0.1.0'
  spec.add_dependency 'bootstrap', '~> 4.6.0'
  spec.add_dependency 'devise'
  spec.add_dependency 'twilio-ruby'
  spec.add_dependency 'interactor'
  spec.add_dependency 'allow_numeric'
  spec.add_dependency 'jquery_mask_rails'
  spec.add_dependency 'dalli'
  spec.add_dependency 'browser'
  spec.add_dependency 'dotiw'
  spec.add_dependency 'redis', '>= 4.2.5'
  spec.add_dependency 'redis-namespace', '>= 1.8.1'
  spec.add_dependency 'switch_user'
  spec.add_dependency 'psych', "< 4"

  spec.add_development_dependency 'annotate'
  spec.add_development_dependency 'spring-watcher-listen'
  spec.add_development_dependency 'spring'
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'web-console'
  spec.add_development_dependency 'byebug'

  spec.add_development_dependency 'capybara', '>= 2.15'
end
