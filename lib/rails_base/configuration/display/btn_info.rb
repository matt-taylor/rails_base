require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class BtnInfo < Base

        DEFAULT_VALUES = {
          dark_mode: {
            type: :string_nil,
            default: 'btn-info',
            description: 'Button info to use in Dark mode'
          },
          light_mode: {
            type: :string_nil,
            default: 'btn-info',
            description: 'Button info to use in light mode'
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
