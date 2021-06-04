# frozen_string_literal: true

class HardWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  DEFAULT_SLEEP = 10

  def perform(sleep_seconds = DEFAULT_SLEEP)
    Sidekiq.logger.info "Night Night for #{sleep_seconds}"
    sleep(sleep_seconds)
    Sidekiq.logger.info 'Back alive'
  end
end
