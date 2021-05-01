module RailsBase
  class Engine < ::Rails::Engine
    isolate_namespace RailsBase

    initializer 'instantiate RailsBase configs' do |_app|
      RailsBase.config
    end

    initializer 'remove write access to RailsBase config', after: 'after_initialize' do |app|
      RailsBase::Configuration::Base._unset_allow_write!
    end

    initializer 'define magic convenionce methods for converting team', after: 'active_record.initialize_database' do |app|
      # Only execute when not doing DB actions
      boolean = defined?(ARGV) ? true : false  # for when no ARGVs are provided, we know its a railsc or rails s explicit
      boolean = false if boolean && ARGV[0]&.include?('db') # when its the DB rake tasks
      boolean = false if boolean && ARGV[0]&.include?('asset') # when its an asset
      boolean = false if boolean && ARGV[0]&.include?(':') # else this delim should never be included
      boolean = false if boolean && ENV['SKIP_CUSTOM_INIT']=='true' # explicitly set the variable to skip shit

      if boolean
        # need to eager load Models
        Rails.application.eager_load!

        # create a connection
        ActiveRecord::Base.retrieve_connection

        #explicitly load engine routes
        Dir.entries(RailsBase::Engine.root.join('app','models')).select{|s| s.ends_with?('.rb')}.each {|f| require f}
        RailsBase::ApplicationRecord.descendants.each do |model|
          model._magically_defined_time_objects
        end
      end
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
