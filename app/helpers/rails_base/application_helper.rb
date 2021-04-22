module RailsBase::ApplicationHelper
  APPEARANCE_MODE_COOKIE = "_#{Rails.application.class.parent_name}_appearance_mode".gsub(' ', '-').downcase
  APPEARANCE_TEXT_CLASS = 'color-text-class'

  def appearance_mode_drop_down
    current = cookies[APPEARANCE_MODE_COOKIE]
    current = cookies[APPEARANCE_MODE_COOKIE]
    types = RailsBase::Configuration::Appearance::APPEARANCE_TYPES
    logger.fatal { "Failed to find the cookie. Given[#{current&.to_sym}]. expected #{types}" }
    unless types.include?(current&.to_sym)
      cookies[APPEARANCE_MODE_COOKIE] = current = RailsBase.appearance.default_mode
    end
    { types: types, current: current }
  end

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
