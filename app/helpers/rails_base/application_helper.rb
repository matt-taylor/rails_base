module RailsBase::ApplicationHelper

  TIMEZONE_OFFSET_COOKIE = "_#{Rails.application.class.parent_name}_timeoffset"
  TIMEZONE_SESSION_NAME = TIMEZONE_THREAD_NAME = :tz_info

  def browser
    @browser ||= Browser.new(request.user_agent)
  end

  def is_mobile?
    browser.mobile?
  end

  def is_safari?
    browser.safari?
  end

  def mfa_fallback?
    is_mobile? # && is_safari?
  end

  def admin_reset_session!
    session.delete(RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON)
    session.delete(RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY)
  end
end
