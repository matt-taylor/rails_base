module RailsBase
  class Engine < ::Rails::Engine
    isolate_namespace RailsBase

    initializer 'remove switch_user routes', :after => "add_routing_paths" do |app|
      app.routes_reloader.paths.delete_if{ |path| path.include?('switch_user') }
    end
  end
end
