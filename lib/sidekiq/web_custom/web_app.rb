# frozen_string_literal: true

module Sidekiq
  module WebCustom
    class WebApp
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
      end
    end
  end
end
