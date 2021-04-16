module RailsBase
  class Engine < ::Rails::Engine
    isolate_namespace RailsBase

    initializer 'instantiate RailsBase configs' do |_app|
      RailsBase.config
    end

    initializer 'remove write access to RailsBase config', after: 'after_initialize' do |app|
      RailsBase::Configuration::Base._unset_allow_write!
    end

    initializer 'remove switch_user routes', after: 'add_routing_paths' do |app|
      app.routes_reloader.paths.delete_if{ |path| path.include?('switch_user') }
    end

    initializer 'append RailsBase engine migrations' do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
