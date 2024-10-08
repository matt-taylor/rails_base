ENV['RAILS_ENV'] ||= 'test'

if ENV['SIMPLE_COV_RUN'] =='true' && ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  # Needs to be loaded prior to application start
  SimpleCov.start do
    load_profile 'rails' # load_adapter < 0.8
    enable_coverage :branch
    add_group 'Services','app/services'
  end
end

require File.expand_path("../test/dummy/config/environment.rb", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in <#{Rails.env}> mode!") unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'pry'
require 'null_logger'
require 'rails-controller-testing'
Rails::Controller::Testing.install
require 'database_cleaner/active_record'
# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

module ControllerHelper
  def current_user
    user_info = request.session["warden.user.user.key"]
    return nil if user_info.nil?

    User.find(user_info[0][0])
  end

  def user_signed_in?
    !!current_user
  end

  def mfa_event_session_hash(mfa_event:)
    {
      :"__#{RailsBase.app_name}_mfa_events" => {
        mfa_event.event.to_s => mfa_event.to_hash.to_json
      }
    }
  end

  def mfa_event_from_session(event_name:)
    mfa_event = session.dig(:"__#{RailsBase.app_name}_mfa_events", event_name.to_s)
    RailsBase::MfaEvent.new(**JSON.parse(mfa_event).deep_symbolize_keys)
  end

  def mfe_events_from_session
    mfa_events = session.dig(:"__#{RailsBase.app_name}_mfa_events")
    return [] unless Hash === mfa_events

    mfa_events.keys
  end
end


RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ControllerHelper, type: :controller

  config.before(:suite) do
    # seed the DB --- yeah I know. there are better ways to do this
    #
    User.delete_all

    params = {
      email: "some.guy@gmail.com",
      first_name: 'Some',
      last_name: 'Guy',
      phone_number: '6508675309',
      password: "password11",
      password_confirmation: "password11",
      mfa_otp_enabled: true,
      otp_secret: User.generate_otp_secret,
    }
    user = User.create!(params)
    user.generate_otp_backup_codes!

    params = {
      email: "some.guy2@gmail.com",
      first_name: 'Some2',
      last_name: 'Guy2',
      phone_number: '4158675309',
      password: "password22",
      password_confirmation: "password22"
    }
    User.create!(params)

    params = {
      email: "some.guy3@gmail.com",
      first_name: 'Some3',
      last_name: 'Guy3',
      phone_number: '4158675300',
      password: "password33",
      password_confirmation: "password33",
      admin: :owner,
      active: true
    }
    User.create!(params)
  end

  require 'timecop'
  config.before(:each) do
    DatabaseCleaner.start
    Rails.cache.clear
    Timecop.freeze(Time.zone.now)
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Timecop.return
  end

  config.order = :random
  Kernel.srand config.seed
end
