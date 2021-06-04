# frozen_string_literal: true

class ExcludeRandomRaiseWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  def perform(threshold = 0.5)
    raise StandardError, "Yikes. Unlucky. I decided to raise" if rand > threshold.to_f
  end
end
