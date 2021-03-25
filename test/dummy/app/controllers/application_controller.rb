require RailsBase::Engine.root.join('app', 'controllers', 'rails_base', 'application_controller.rb')

class ApplicationController < RailsBase::ApplicationController
  layout 'rails_base/application'
end
