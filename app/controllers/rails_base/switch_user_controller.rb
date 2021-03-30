# frozen_string_literal: true
module RailsBase
  class SwitchUserController < ::SwitchUserController
    before_action :admin_user?
    before_action :admin_user
    after_action :admin_set_impersonation_session!, only: [:set_current_user]

    def admin_set_impersonation_session!
      admin_user
      admin_set_token_on_session(admin_user: admin_user, other_user: provider.current_user)
      session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY] = admin_user.id
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
