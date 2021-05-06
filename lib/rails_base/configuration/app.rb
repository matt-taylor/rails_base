require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class App < Base

      ACTIVE_JOB_PROC = Proc.new do |val, instance|
        begin
          ActiveJob::QueueAdapters.lookup(val)
          Rails.configuration.active_job.queue_adapter = val.to_sym
        rescue
          raise ArgumentError, "config.app.active_job_adapter=#{val} is not a defined active job"
        end
      end

      DEFAULT_VALUES = {
        base_url: {
          type: :string,
          default: ENV.fetch('BASE_URL', 'http://localhost'),
          description: 'Base url. Used for things like SSO.'
        },
        base_port: {
          type: :string_nil,
          default: ENV.fetch('BASE_URL_PORT', nil),
          description: 'Base port. Used for things like SSO.'
        },
        web_name_logged_in: {
          type: :string_proc,
          default: ->(user) { Rails.application.class.parent_name },
          description: 'Name of the application when authenticated user is present. Name in the tab of the browser. Allows for dynamic tab names'
        },
        web_name_logged_out: {
          type: :string_proc,
          default: ->(*) { Rails.application.class.parent_name },
          description: 'Name of the application when no authenticated user. Name in the tab of the browser. Allows for dynamic tab names'
        },
        web_title_logged_in: {
          type: :string_proc,
          default: ->(user) { Rails.application.class.parent_name },
          description: 'Title in nav for the web when logged in. String or proc accepted. When proc, current user will be passed in.'
        },
        web_title_logged_out: {
          type: :string_proc,
          default: ->(*) { Rails.application.class.parent_name },
          description: 'Title in nav for the web when logged in. String or proc accepted. When proc, current user will be passed in.'
        },
        communication_name: {
          type: :string_proc,
          default: ->(*) { Rails.application.class.parent_name },
          description: 'Name used when communicating with users.'
        },
        favicon_path: {
          type: :string_nil,
          default: 'rails_base/favicon.ico',
          description: 'Favicon path'
        },
        active_job_adapter: {
          type: :string,
          default: 'sidekiq',
          on_assignment: ACTIVE_JOB_PROC,
          description: 'Active job adapter. This should most lkely be sidekiq.'
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
