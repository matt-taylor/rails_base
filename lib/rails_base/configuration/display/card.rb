require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class Card < Base
        DEFAULT_VALUES = {
          dark_mode: {
            type: :string_nil,
            default: 'bg-dark',
            description: 'Color of card for dark mode: https://getbootstrap.com/docs/4.0/utilities/colors/'
          },
          light_mode: {
            type: :string_nil,
            default: '',
            description: 'Color of card for light mode : https://getbootstrap.com/docs/4.0/utilities/colors/'
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
