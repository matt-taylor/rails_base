# frozen_string_literal: true

class TostadaWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  def perform(*)
    Rails.logger.warn { 'You are a Tostada' }
  end
end
