require 'rails_base/configuration/base'
require 'rails_base/configuration/display/table_header'
require 'rails_base/configuration/display/table_body'
require 'rails_base/configuration/display/background_color'
require 'rails_base/configuration/display/navbar'
require 'rails_base/configuration/display/text'

module RailsBase
  module Configuration
    class Appearance < Base
      DOWNSTREAM_CLASSES = [
        :t_header,
        :t_body,
        :bg_color,
        :navbar,
        :text,
      ]

      APPEARANCE_TYPES = [
        DARK_MODE = :dark,
        LIGHT_MODE = :light
      ]

      DEFAULT_VALUES = {
        enabled: {
          type: :boolean,
          default: true,
          description: 'When disabled, the user will be forced into default_mode when appropriate'
        },
        default_mode: {
          type: :values,
          expect_values: APPEARANCE_TYPES,
          default: LIGHT_MODE,
          description: 'Default mode to set when mode not found in cookies/session'
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
      attr_reader *DOWNSTREAM_CLASSES

      def initialize
        #####
        # all display classes are required to have APPEARANCE_TYPES as default values
        #####
        @t_header = Configuration::Display::TableHeader.new
        @t_body = Configuration::Display::TableBody.new
        @bg_color = Configuration::Display::BackgroundColor.new
        @navbar = Configuration::Display::Navbar.new
        @text = Configuration::Display::Text.new

        super()
      end

      def validate!
        super()
        DOWNSTREAM_CLASSES.each do |variable|
          instance_variable_get("@#{variable}").validate!
        end
      end

      def assign_default_values!
        super()
        DOWNSTREAM_CLASSES.each do |variable|
          instance_variable_get("@#{variable}").assign_default_values!
        end
      end
    end
  end
end


