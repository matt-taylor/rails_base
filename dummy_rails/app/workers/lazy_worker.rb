# frozen_string_literal: true

class LazyWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  def perform(*)
  end
end
