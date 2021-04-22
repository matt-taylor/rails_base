require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class Text < Base

        DEFAULT_VALUES = {
          dark_mode: {
            type: :string_nil,
            default: 'text-white',
            description: 'Color of text for dark mode. Text that is outside of standard elems (tables, navbars): https://getbootstrap.com/docs/4.0/utilities/colors/'
          },
          light_mode: {
            type: :string_nil,
            default: 'text-dark',
            description: 'Color of text for light mode. Text that is outside of standard elems (tables, navbars): https://getbootstrap.com/docs/4.0/utilities/colors/'

          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
