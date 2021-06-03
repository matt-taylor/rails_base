require 'sidekiq/processor'

module Sidekiq
  module WebCustom
    class Processor < ::Sidekiq::Processor

      def self.execute(max:, queue:, options: Sidekiq.options)
        __processor__(queue: queue, options: options).__execute(max: max)
      end

      def self.execute_job(job:, options: Sidekiq.options)
        __processor__(queue: job.queue, options: options).__execute_job(job: job)
      rescue StandardError => _
        false # error gets loggged downstream
      end

      def self.__processor__(queue:, options: Sidekiq.options)
        options_temp = options.clone
        queue = queue.is_a?(String) ? Sidekiq::Queue.new(queue) : queue
        options_temp[:queues] = [queue.name]
        klass = options_temp[:fetch]&.class || BasicFetch
        options_temp[:fetch] = klass.new(options_temp)
        processor = new(manager: nil, options: options_temp, queue: queue)
      end

      def initialize(manager:, options:, queue:)
        @__queue = queue
        @__basic_fetch = options[:fetch].class == BasicFetch

        super(manager, options)
      end

      def __execute_job(job:)
        queue_name = "queue:#{job.queue}"
        work_unit = Sidekiq::BasicFetch::UnitOfWork.new(queue_name, job.item.to_json)
        begin
          Sidekiq.logger.info { "Manually processing individual work unit for #{work_unit.queue_name}" }
          process(work_unit)
        rescue StandardError => e
          Sidekiq.logger.error { "Manually processed work unit failed with #{e.message}. Work unit will not be dequeued" }
          raise e
        end

        begin
          Sidekiq.logger.error { "Manually processed work unit sucessfully dequeued." }
          job.delete
        rescue StandardError => e
          Sidekiq.logger.error { "Manually processed work unit failed to be dequeued. #{e.message}." }
          raise e
        end

        true
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

