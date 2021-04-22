require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class Navbar < Base

        DEFAULT_VALUES = {
          dark_mode: {
            type: :string_nil,
            default: 'navbar-dark bg-dark',
            description: 'Background to use in Dark mode'
          },
          light_mode: {
            type: :string_nil,
            default: 'navbar-light bg-light',
            description: 'Background to use in light mode'
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
