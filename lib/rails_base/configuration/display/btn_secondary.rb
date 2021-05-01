require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class BtnSecondary < Base

        DEFAULT_VALUES = {
          dark_mode: {
            type: :string_nil,
            default: 'btn-light',
            description: 'Button secondary to use in Dark mode. Please use btn_secondary as primary attribute instead of btn-secondary'
          },
          light_mode: {
            type: :string_nil,
            default: 'btn-secondary',
            description: 'Button secondary to use in light mode.  Please use btn_secondary as primary attribute instead of btn-secondary'
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
