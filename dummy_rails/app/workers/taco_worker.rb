# frozen_string_literal: true

class TacoWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  def perform(*)
    Rails.logger.warn { 'You are a Taco' }
    sleep(rand*10)
  end
end
