# Changelog

## v0.75.1
- Allow Ruby version to be customizable
- This way, the Gemfile can use the default ruby that CI setups and Heroku can evaluate which version to use

## v0.75.0
- Rails 6.1 or greater enforced
- Zeitwerk 2.6.5 or greater enforced
- Zeitwerk compatability -- Paves the way for rails 7 compatability
- [Fix] Add native way to re-open classes downstream
```ruby
# application.rb

module Dummy
  class Application < Rails::Application
    ...
    # Enforce Zeitwerk is the autoloader
    # This is recommended and will be enforced soon enough!
    config.autoloader = :zeitwerk

    # Allow all files under `app/models` to be re-opened by the Dummy Application
    RailsBase.reloadable_paths!(relative_path: "app/models")
    # Or to just reload the user model
    RailsBase.reloadable_paths!(only_files: ["app/models/user.rb"])
    ...
  end
end
```
