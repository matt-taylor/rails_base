require 'sidekiq/web_custom/processor'

module Sidekiq
  module WebCustom
    module Job
      def execute
        Sidekiq::WebCustom::Processor.execute_job(job: self)
      end
    end
  end
end
