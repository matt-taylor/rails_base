module RailsBase
  class AdminController < ApplicationController
    skip_before_action :admin_reset_impersonation_session!

    # GET admin/impersonate/:scope_identifier
    def index

    end

    # POST admin/impersonate
    def switch_back
      unless original_user_id = session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY]
        # something wonky happend to the session. Kick user back to homepage and relogin
        warden.logout(:user)
        flash[:alert] = 'Unknown failure. Please log in again'
        redirect_to RailsBase.url_routes.unauthenticated_root_path
        session.clear
        return
      end

      # use warden here so that we dont add to devise signin/out hooks
      warden.set_user(User.find(original_user_id), scope: :user)

      # Critical step to ensure subsequent apps dont think we are an impersonation
      session.delete(RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON)

      flash[:notice] = 'You no longer have an identity crisis. You are back to normal.'
      redirect_to RailsBase.url_routes.admin_base_path
    end
  end
end
