module RailsBase
  module Configuration
    class ActiveJob < Base
      DEFAULT_VALUES = {
        enable_ui: {
          type: :boolean,
          default: true,
          description: 'All ActiveJob UI. To be used downstream'
        },
        view_ui: {
          type: :proc,
          default: ->(user) { user.at_least_owner? },
          dependents: [ -> (i) { i.enable_ui? }],
          description: 'All users to view ActiveJob UI. To be used downstream'
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
