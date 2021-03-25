module RailsBase::ApplicationHelper
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
end
