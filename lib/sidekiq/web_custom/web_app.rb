# frozen_string_literal: true

module Sidekiq
  module WebCustom
    class WebApp
      MAPPED_TYPE = {
        retries: RetrySet,
        scheduled: ScheduledSet,
      }
      def self.registered(app)
        app.post '/queues/drain/:name' do
          timeout_params = {
            warn: Sidekiq::WebCustom.config.warn_execution_time,
            timeout: Sidekiq::WebCustom.config.max_execution_time,
            proc: ->(thread, seconds) { thread[Sidekiq::WebCustom::BREAK_BIT] = 1; puts "set bit #{thread[Sidekiq::WebCustom::BREAK_BIT]}" }
          }
          Thread.current[Sidekiq::WebCustom::BREAK_BIT] = nil
          Sidekiq::WebCustom::Timeout.timeout(timeout_params) do
            Sidekiq::Queue.new(params[:name]).drain(max: Sidekiq::WebCustom.config.drain_rate)
          end
          redirect_with_query("#{root_path}queues")
        rescue Sidekiq::WebCustom::ExecutionTimeExceeded => e
          redirect_with_query("#{root_path}queues")
        end

        app.post '/job/delete' do
          parsed = parse_params(params['entry.score'])

          klass = MAPPED_TYPE[params['entry.type'].to_sym]
          job = klass.new.fetch(*parsed)&.first

          job&.delete
          redirect_with_query("#{root_path}scheduled")
        end

        app.post '/job/execute' do
          parsed = parse_params(params['entry.score'])

          klass = MAPPED_TYPE[params['entry.type'].to_sym]
          job = klass.new.fetch(*parsed)&.first

          status = job&.execute
          redirect_with_query("#{root_path}#{params['entry.type']}")
        end
      end
    end
  end
end
