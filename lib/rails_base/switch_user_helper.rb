require 'switch_user'

module RailsBase
  module SwitchUserHelper
    def switch_user_custom(options = {})
      return unless available?

      selected_user = nil

      grouped_options_container =
        {}.tap do |h|
          SwitchUser.all_users.each do |record|
            scope = record.is_a?(SwitchUser::GuestRecord) ? :Guest : record.scope.to_s.capitalize
            h[scope] ||= []
            h[scope] << [record.label, record.scope_id]

            next unless selected_user.nil?
            next if record.is_a?(SwitchUser::GuestRecord)

            selected_user = record.scope_id if provider.current_user?(record.user, record.scope)
          end
        end

      option_tags = grouped_options_for_select(grouped_options_container.to_a, selected_user)

      render partial: 'rails_base/switch_user/widget',
             locals: { option_tags: option_tags, classes: options[:class], styles: options[:style] }
    end

    private

    def available?
      SwitchUser.guard_class.new(controller, provider).view_available?
    end
  end
end
