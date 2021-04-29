require 'rails_base/configuration/base'
require 'rails_base/configuration/display/table_header'
require 'rails_base/configuration/display/table_body'
require 'rails_base/configuration/display/background_color'
require 'rails_base/configuration/display/navbar'
require 'rails_base/configuration/display/text'
require 'rails_base/configuration/display/footer'

module RailsBase
  module Configuration
    class Appearance < Base
      DOWNSTREAM_CLASSES = [
        :t_header,
        :t_body,
        :bg_color,
        :navbar,
        :text,
        :footer
      ]
      SKIP_DOWNSTREAM_CLASSES = [:footer]
      DARK_MODE = :dark
      LIGHT_MODE = :light
      MATCH_OS = :match_os

      ALLOWABLE_TYPES = {
        DARK_MODE => 'Dark Mode',
        LIGHT_MODE => 'Light Mode',
      }

      APPEARANCE_TYPES = ALLOWABLE_TYPES.merge(MATCH_OS => 'Match System')

      DEFAULT_VALUES = {
        enabled: {
          type: :boolean,
          default: true,
          description: 'When disabled, the user will be forced into default_mode when appropriate'
        },
        default_mode: {
          type: :values,
          expect_values: APPEARANCE_TYPES.keys,
          default: LIGHT_MODE,
          description: 'Default mode to set when mode not found in cookies/session',
        },

        math_os_dark: {
          type: :values,
          expect_values: ALLOWABLE_TYPES.keys,
          default: DARK_MODE,
          description: 'Mode to set when OS returns dark mode (useful when more than light/dark mode',
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
      attr_reader *DOWNSTREAM_CLASSES

      def initialize
        #####
        # all display classes are required to have ALLOWABLE_TYPES as default values
        #####
        @t_header = Configuration::Display::TableHeader.new
        @t_body = Configuration::Display::TableBody.new
        @bg_color = Configuration::Display::BackgroundColor.new
        @navbar = Configuration::Display::Navbar.new
        @text = Configuration::Display::Text.new
        @footer = Configuration::Display::Footer.new

        _validate_values
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

      private
      def _validate_values
        DOWNSTREAM_CLASSES.each do |var|
          next if SKIP_DOWNSTREAM_CLASSES.include?(var)

          ALLOWABLE_TYPES.each do |k, v|
            next if public_send(var).respond_to?("#{k}_mode")

            raise ArgumentError, "#{var} does not respond to #{k}_mode"
          end
        end
      end
    end
  end
end


