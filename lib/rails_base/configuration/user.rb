require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class User < Base
      USER_DEFINED_KEY = 'User Defined Zone'
      USER_DEFINED_ZONE = { USER_DEFINED_KEY => ->(user) { user.last_known_timezone } }
      ACTIVE_SUPPORT_MAPPING = ActiveSupport::TimeZone::MAPPING.map do |key, value|
        [key, ->(*) { value }]
      end.to_h

      DEFAULT_TIMEZONES = {
        '' => ->(*) { ActiveSupport::TimeZone::MAPPING['UTC'] },
        nil => ->(*) { ActiveSupport::TimeZone::MAPPING['UTC'] },
      }

      ACCEPTED_TIMEZONES = DEFAULT_TIMEZONES.merge(ACTIVE_SUPPORT_MAPPING).merge(USER_DEFINED_ZONE)

      DEFAULT_VALUES = {
        timezone: {
          type: :values,
          default: USER_DEFINED_KEY,
          description: 'The timezone to display to user.',
          on_assignment: ->(val, instance) { instance._timezone_convenience },
          expect_values: ACCEPTED_TIMEZONES.keys,
        },
      }

      attr_accessor *DEFAULT_VALUES.keys

      def _timezone_convenience
        value = ACCEPTED_TIMEZONES[timezone]
        self.class.define_method('user_timezone') do |user|
          value.call(user) || ActiveSupport::TimeZone::MAPPING['UTC']
        end

        self.class.define_method('tz_user_defined?') do
          timezone == USER_DEFINED_KEY
        end
      end
    end
  end
end
