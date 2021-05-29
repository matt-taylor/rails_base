module RailsBase
  module Configuration
    class ActiveJob < Base
      ACTIVE_JOB_PROC = Proc.new do |val, instance|
        if val.is_a?(Symbol)
          begin
            ::ActiveJob::QueueAdapters.lookup(val)
            Rails.configuration.active_job.queue_adapter = val.to_sym
          rescue StandardError => e
            raise ArgumentError, "config.app.active_job_adapter=#{val} is not a defined active job"
          end
        end
      end

      DEFAULT_VALUES = {
        enable_ui: {
          type: :boolean,
          default: true,
          description: 'All ActiveJob UI. To be used downstream'
        },
        view_ui: {
          type: :proc,
          default: ->(user) { user.at_least_owner? },
          dependents: [ -> (i) { i.enable_ui? }],
          description: 'All users to view ActiveJob UI. To be used downstream'
        },
        adapter: {
          type: :symbol_class,
          default: :inline,
          on_assignment: ACTIVE_JOB_PROC,
          description: 'Active job adapter. This expects a symbol or a class that inherits from ActiveJob::QueueAdapters'
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
