require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    module Display
      class Footer < Base
        DEFAULT_PAGES = {
          'RailsBase::Users::SessionsController' => [:new, :create],
          'RailsBase::Users::PasswordsController' => [:new],
          'RailsBase::Users::RegistrationsController' => [:new],
          'RailsBase::UserSettingsController' => [:index],
          'RailsBase::MfaAuthController' => [:mfa_code],
          'RailsBase::SecondaryAuthenticationController' => [:static, :after_email_login_session_new, :forgot_password],
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
            dependents: [ -> (i) { i.enable? } ],
            description: 'Stick footer to the bottom of screen',
          },
          sticky_pages: {
            type: :hash,
            default: DEFAULT_PAGES,
            popover: true,
            decipher: ->(thing) { thing.map { |k, v| v.map { |a| "#{k}.#{a}"  } }.flatten },
            description: 'Pages that use sticky pages. All others wil append footer to end of body. NOTE: Action can be forced by calling `force_sticky_mode!` anytime.',
          },
          html: {
            type: :string,
            default: DEFAULT_FOOTER_HTML,
            description: 'HTML text to be placed at footer'
          },
          content_bottom_or_sticky: {
            type: :boolean,
            default: true,
            dependents: [ -> (i) { i.enable? } ],
            description: 'When enabled, footer will stick to bottom or stick to bottom of content -- whichever is greater. Takes precendence over `sticky`',
          },

        }

        attr_accessor *DEFAULT_VALUES.keys
      end
    end
  end
end
