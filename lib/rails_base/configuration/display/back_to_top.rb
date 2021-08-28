require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class BackTotop < Base

        DEFAULT_VALUES = {
          enable: {
            type: :boolean,
            default: true,
            description: 'Enable Back to top icon on all pages',
          },
        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
