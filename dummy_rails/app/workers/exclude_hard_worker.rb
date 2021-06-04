# frozen_string_literal: true

class ExcludeHardWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  DEFAULT_SLEEP = 10.seconds

  def perform(sleep_seconds = DEFAULT_SLEEP)
    Sidekiq.logger.info "I am a harrrddddd worker. I go nap for #{sleep_seconds} seconds"
    sleep(sleep_seconds)
    Sidekiq.logger.info "Good nap"
  end
end
