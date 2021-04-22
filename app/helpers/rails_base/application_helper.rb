module RailsBase::ApplicationHelper
  APPEARANCE_MODE_COOKIE = "_#{Rails.application.class.parent_name}_appearance_mode".gsub(' ', '-').downcase
  APPEARANCE_TEXT_CLASS = RailsBase::Configuration::Display::Text::APPEARANCE_TEXT_CLASS

  def appearance_text_class
    APPEARANCE_TEXT_CLASS
  end

  def appearance_mode_drop_down
    current = cookies[APPEARANCE_MODE_COOKIE]
    current = cookies[APPEARANCE_MODE_COOKIE]
    raw_types = RailsBase::Configuration::Appearance::APPEARANCE_TYPES
    types_a = raw_types.map(&:to_a).map(&:flatten).map(&:reverse)
    types = raw_types.keys
    unless types.include?(current&.to_sym)
      cookies[APPEARANCE_MODE_COOKIE] = current = raw_types[RailsBase.appearance.default_mode]
    end
    { types: types, current: current, types_a: types_a }
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
