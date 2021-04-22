require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class TableBody < Base

        DEFAULT_VALUES = {
          dark_mode: {
            type: :string_nil,
            default: 'table-dark',
            description: 'Table Body to use in Dark mode'
          },
          light_mode: {
            type: :string_nil,
            default: '',
            description: 'Table Body to use in light mode'
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
