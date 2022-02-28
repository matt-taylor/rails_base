module RailsBase
  class Engine < ::Rails::Engine
    isolate_namespace RailsBase

    # config.autoload_paths << File.expand_path("app", __dir__)

    ActiveSupport::Reloader.to_prepare do
      if RailsBase.___execute_initializer___?
        RailsBase.config.admin.convenience_methods

        Dir[RailsBase::Engine.root.join('app','models','**', '*.rb')].each {|f| require f }
        RailsBase::ApplicationRecord.descendants.each do |model|
          model._magically_defined_time_objects
        end
      end
    end

    initializer 'rails_base.config.intantiate' do |_app|
      RailsBase.config if RailsBase.___execute_initializer___?
    end

    initializer 'rails_base.config.remove_write_acess', after: 'after_initialize' do |app|
      RailsBase::Configuration::Base._unset_allow_write! if RailsBase.___execute_initializer___?
    end

    initializer 'rails_base.magic_convenience_methods.model', after: 'active_record.initialize_database' do |app|
      if RailsBase.___execute_initializer___?
        # need to eager load Models
        Rails.application.eager_load!

        # create a connection
        ActiveRecord::Base.retrieve_connection

        #explicitly load engine routes
        RailsBase::ApplicationRecord.descendants.each do |model|
          model._magically_defined_time_objects
        end
      end
    end

    initializer 'rails_base.switch_user.remove_routes', after: 'add_routing_paths' do |app|
      app.routes_reloader.paths.delete_if{ |path| path.include?('switch_user') }
    end

    initializer 'rails_base.append_engine_migrations' do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer 'rails_base.switch_user.view' do
      config.to_prepare do
        ActiveSupport.on_load(:action_view) do

          include RailsBase::SwitchUserHelper
        end
      end
    end
  end
end
