module RailsBase
  module Configuration
    class Sidekiq < Base
      DEFAULT_VALUES = {
        enable_ui: {
          type: :boolean,
          default: true,
          description: 'Enable Sidekiq UI capabilities'
        },
        view_ui: {
          type: :proc,
          default: ->(user) { user.at_least_owner? },
          dependents: [ -> (i) { i.enable_ui? }],
          description: 'Enable Sidekiq UI capabilities'
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
