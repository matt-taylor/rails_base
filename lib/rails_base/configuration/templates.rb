require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Templates < Base

      DEFAULT_VALUES = {
        logged_in_header_modal: {
          type: :string_nil,
          default: nil,
          description: 'The template to render in the logged in header modal. `current_user` is passed in',
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
