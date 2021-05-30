require 'sidekiq/processor'

module Sidekiq
  module WebCustom
    class Processor < ::Sidekiq::Processor
      def self.execute(max:, queue:, options: Sidekiq.options)
        options[:queues] = [queue.name]
        options[:fetch] = BasicFetch.new(options)
        processor = new(manager: nil, options: options, queue: queue)
        processor.execute(max: max)
      end

      def initialize(manager:, options:, queue:)
        @__queue = queue

        super(manager, options)
      end

      def execute_job(job:)

      end

      def execute(max:)
        count = 0
        max.times do
          break if @__queue.size <= 0
          count += 1
          Sidekiq.logger.info { "Manually processing next item in queue:[#{@__queue}]" }
          process_one
        end
        count
      rescue Exception => ex
        if @job
          Sidekiq.logger.fatal "Processor Execution interupted. Lost Job #{@job}"
        end
      end
    end
  end
end

# Sidekiq::WebCustom::Processor
