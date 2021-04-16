# frozen_string_literal: true
module RailsBase
  class SwitchUserController < ::SwitchUserController
    before_action :admin_user?
    before_action :admin_user
    before_action :can_impersonate?
    after_action :admin_set_impersonation_session!, only: [:set_current_user]

    def admin_set_impersonation_session!
      admin_set_token_on_session(admin_user: admin_user, other_user: provider.current_user)
      session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY] = admin_user.id
    end

    def can_impersonate?
      return if RailsBase.config.admin.impersonate_tile_users.call(admin_user)

      flash[:alert] = "You do not have correct permissions to impersonate users"
      redirect_to RailsBase.url_routes.admin_base
    end

    def admin_user
      if session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY]
        User.find session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY]
      else
        current_user
      end
    end
  end
end
