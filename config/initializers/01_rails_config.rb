####################################################
# File is prepended with 01 so that it loads first #
####################################################

require 'link_decision_helper'

Rails.application.configure do
  # Ensure that RailBase assets get compiled
  config.assets.precompile << 'rails_base/manifest'

  # ToDo: Move this to a configuration similar to admin tiles
  #################################
  # Define logged in Header paths #
  #################################
  LinkDecisionHelper::ALLOWED_TYPES.each do |type|
    thing = config.public_send("#{type} ||=", [])
    config.public_send("#{type}=", []) if thing.empty?
  end
end
