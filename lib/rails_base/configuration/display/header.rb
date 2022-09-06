require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class Header < Base

        DEFAULT_VALUES = {
          partial: {
            type: :string_nil,
            default: nil,
            description: "Rails partial to render at the header."
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
