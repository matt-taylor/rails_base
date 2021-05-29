$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rails_base/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rails_base"
  spec.version     = RailsBase::VERSION
  spec.authors     = ["Matt Taylor"]
  spec.email       = ["mattius.taylor@gmail.com"]
  spec.summary     = "This is a summary"
  spec.description = "This is a description"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://gemfury.com'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end
  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 5"
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

  spec.add_development_dependency 'annotate'
  spec.add_development_dependency 'spring-watcher-listen'
  spec.add_development_dependency 'spring'
  spec.add_development_dependency 'listen'
  spec.add_development_dependency 'web-console'
  spec.add_development_dependency 'byebug'

  spec.add_development_dependency 'capybara', '>= 2.15'
end
