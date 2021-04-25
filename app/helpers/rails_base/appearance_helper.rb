module RailsBase::AppearanceHelper
  APPEARANCE_MODE_COOKIE = "_#{Rails.application.class.parent_name}_appearance_mode".gsub(' ', '-').downcase
  APPEARANCE_MODE_ACTUAL_COOKIE = "_#{Rails.application.class.parent_name}_appearance_actual_mode".gsub(' ', '-').downcase
  APPEARANCE_TEXT_CLASS = RailsBase::Configuration::Display::Text::APPEARANCE_TEXT_CLASS

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
