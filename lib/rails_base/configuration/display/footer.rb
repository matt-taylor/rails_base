require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class Footer < Base
        DEFAULT_PAGES = {
          'RailsBase::Users::SessionsController' => [:new],
          'RailsBase::Users::RegistrationsController' => [:new],
          'RailsBase::UserSettingsController' => [:index],
        }
        DEFAULT_FOOTER_HTML = "© 2021 Year of the Rona: Bad Ass Rails Starter <a href='https://github.com/matt-taylor/' target='_blank'>@matt-taylor</a>"

        DEFAULT_VALUES = {
          enable: {
            type: :boolean,
            default: true,
            description: 'Enable footer for the site',
          },
          sticky: {
            type: :boolean,
            default: true,
            description: 'Stick footer to the bottom of screen',
          },
          sticky_pages: {
            type: :hash,
            default: DEFAULT_PAGES,
            description: 'Pages that use sticky pages. All others wil append footer to end of body. NOTE: Action can be forced by calling `force_sticky_mode!` anytime.',
          },
          html: {
            type: :string,
            default: DEFAULT_FOOTER_HTML,
            dependents: [ -> (i) { i.enable? } ],
            description: 'HTML text to be placed at footer'
          },

        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
