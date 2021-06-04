# frozen_string_literal: true

class ExcludeLazyWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  def perform(*)
    Sidekiq.logger.info "I am a lazy worker"
  end
end
