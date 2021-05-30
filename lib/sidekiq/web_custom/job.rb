require 'sidekiq/web_custom/processor'

module Sidekiq
  module WebCustom
    module Queue
      def drain(max:)
        count = [size, max].min
        Sidekiq::WebCustom::Processor.execute(max: count, queue: self)
      end
    end
  end
end
