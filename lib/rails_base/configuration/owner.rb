require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Owner < Base
      DEFAULT_VALUES = {
        max: { type: :integer, default: 1 }
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
