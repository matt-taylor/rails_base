# Changelog

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
    ...
  end
end
```
