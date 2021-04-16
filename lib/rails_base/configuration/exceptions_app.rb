require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class ExceptionsApp < Base

      EXCEPTIONS_PROC = Proc.new do |val|
        Rails.configuration.exceptions_app = val
      end

      DEFAULT_VALUES = {
        exceptions_app: {
          type: :klass,
          klass_type: [ActionDispatch::Routing::RouteSet],
          default: nil,
          default_assign_on_boot: -> { Rails.application.routes },
          on_assignment: EXCEPTIONS_PROC,
          description: 'What route set to find the exceptions on.'
        }
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
