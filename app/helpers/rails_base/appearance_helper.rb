module RailsBase::AppearanceHelper
  APPEARANCE_MODE_COOKIE = "_#{Rails.application.class.parent_name}_appearance_mode".gsub(' ', '-').downcase
  APPEARANCE_MODE_ACTUAL_COOKIE = "_#{Rails.application.class.parent_name}_appearance_actual_mode".gsub(' ', '-').downcase
  APPEARANCE_TEXT_CLASS = RailsBase::Configuration::Display::Text::APPEARANCE_TEXT_CLASS

  VIEWPORT_EXTRA_SMALL = 'xs'.freeze
  VIEWPORT_SMALL = 'sm'.freeze
  VIEWPORT_MEDIUM = 'md'.freeze
  VIEWPORT_LARGE = 'lg'.freeze
  VIEWPORT_EXTRA_LARGE = 'xl'.freeze

  VIEWPORT_MOBILE_MAX = VIEWPORT_MEDIUM

  VIEWPORT_SIZES = {
    VIEWPORT_EXTRA_SMALL => 576,
    VIEWPORT_SMALL => 768,
    VIEWPORT_MEDIUM => 992,
    VIEWPORT_LARGE => 1200,
    VIEWPORT_EXTRA_LARGE => nil,
  }

  def appearance_text_class
    APPEARANCE_TEXT_CLASS
  end

  def appearance_mode_drop_down
    @appearance_mode_drop_down ||= begin
      current = cookies[APPEARANCE_MODE_COOKIE]
      actual = cookies[APPEARANCE_MODE_ACTUAL_COOKIE]
      raw_types = RailsBase::Configuration::Appearance::APPEARANCE_TYPES
      types_a = raw_types.map(&:to_a).map(&:flatten).map(&:reverse)
      types = raw_types.keys
      unless types.include?(current&.to_sym)
        cookies[APPEARANCE_MODE_COOKIE] = current = RailsBase.appearance.default_mode
      end
      { types: types, current: current, types_a: types_a, actual: actual }
    end
  end
end
