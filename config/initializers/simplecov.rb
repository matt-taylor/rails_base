
if ENV['RAILS_ENV']=='test' && (ENV.fetch('SIMPLE_COV_RUN', 'false')=='true')
  require 'simplecov'
  SimpleCov.configure do
    add_filter do |source_file|
      source_file.lines.count < 6
    end
    add_group 'Services', 'app/services/rails_base'
  end
  SimpleCov.start 'rails'
  Dir[RailsBase::Engine.root.join('lib/*.rb')].each {|file| load file }
end
