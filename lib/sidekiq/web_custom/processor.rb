require 'sidekiq/processor'

module Sidekiq
  module WebCustom
    class Processor < ::Sidekiq::Processor

      def self.execute(max:, queue:, options: Sidekiq.options)
        options_temp = options.clone
        options_temp[:queues] = [queue.name]
        klass = options_temp[:fetch]&.class || BasicFetch
        options_temp[:fetch] = klass.new(options_temp)
        processor = new(manager: nil, options: options_temp, queue: queue)
        processor.__execute(max: max)
      end

      def initialize(manager:, options:, queue:)
        @__queue = queue
        @__basic_fetch = options[:fetch].class == BasicFetch

        super(manager, options)
      end

      def __execute(max:)
        count = 0
        max.times do
          break if @__queue.size <= 0
          if Thread.current[Sidekiq::WebCustom::BREAK_BIT]
            Sidekiq.logger.warn { "Yikes -- Break bit has been set. Attempting to return in time. Completed #{count} of attempted #{max}" }
            break
          end
          count += 1
          Sidekiq.logger.info { "Manually processing next item in queue:[#{@__queue.name}]" }
          process_one
        end
        count
      rescue Exception => ex
        if @job && @__basic_fetch
          Sidekiq.logger.fatal "Processor Execution interrupted. Lost Job #{@job.job}"
        end
        raise ex
      end
    end
  end
end

