require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class BgLight < Base

        DEFAULT_VALUES = {
          dark_mode: {
            type: :string_nil,
            default: 'bg-secondary',
            description: 'Background to use in Dark mode'
          },
          light_mode: {
            type: :string_nil,
            default: 'bg-light',
            description: 'Background to use in light mode'
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
