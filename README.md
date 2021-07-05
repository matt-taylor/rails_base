# Sidekiq::WebCustom

Sidekiq::WebCustom adds additional flexibility to your Sidekiq UI.
- What happens if you do not have a Sidekiq Server?
- What happens if your Sidekiq Server does not bind to a queue that is ever growing?

This Custom add on to the Sidekiq Web framework allows you to continue to drain your queue's even when Sidekiq is not bound to them

## Installation

Add this line to your application's Gemfile:
```ruby
gem 'sidekiq-web_custom'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sidekiq-web_custom

## Usage

### Configuration
#### Initializer
Add an intilizer file to boot SidekiqUI with the expected plugins `config/initializers/sidekiq-web_custom.rb`. When not providing a block, this will use the default configuration values.
```ruby
# config/initializers/sidekiq-web_custom.rb

require 'sidekiq/web_custom'
Sidekiq::WebCustom.configure
```

#### Options
```ruby
require 'sidekiq/web_custom'
Sidekiq::WebCustom.configure do |config|
    # Max number to attempt to drain from a queue at a time
    # Warning: A high number or long runnnig job will potentially block the process for longer
    config.drain_rate = 10 # default is 10 seconds

    # Max time to allow for execution of draining
    # If time exceeds this number, the process will violently quit.
    # Set warning time wisely
    config.max_execution_time = 6 # default is 6 second

    # Max time before we attempt to send warning to halt execution.
    # This will prevent the process from trying to attempt work on another job
    # If a long running job is occuring, this will not stop the job. It will meet a violent end
    config.warn_execution_time = 5  # default is 5 second


    # To redefine a local erb like queues, retries, dead, add a new erb like this
    params = { queues: "#{absolute_path}/queues.erb" }
    config.merge(base: :local_erbs, params: params)

    # To add additional actions to a specific local_erb
    # Note Actions that are not attached to an ERB will raise an error
    params = {
        schedule_later: "#{absolute_path}/schedule_later.erb" ,
        delete: "#{absolute_path}/delete.erb" ,
    }
    config.merge(base: :local_erbs, params: params, action_type: :queues)
end
```

## Development

After checking out the repo, run `make build && make bundle` to install dependencies. Then, you can bash into a docker container by using `make bash`.

Similarly, a local dummy app is included with the gem. This allows running `make s` to load a local version of the gem in a isolated ENV.

Please note that changes to the code will require a restart of the server.
Consult the [Makefile](https://github.com/matt-taylor/sidekiq-web_custom/blob/main/Makefile) for additional commands.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matt-taylor/sidekiq-web_custom. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/matt-taylor/sidekiq-web_custom/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sidekiq::Web::Custom project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/matt-taylor/sidekiq-web_custom/blob/main/CODE_OF_CONDUCT.md).
