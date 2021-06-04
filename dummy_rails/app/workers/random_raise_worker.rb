# frozen_string_literal: true

class RandomRaiseWorker
  include Sidekiq::Worker

  sidekiq_options queue: File.basename(__FILE__,'.*').downcase

  def perform(raise_sample = 0.5)
    raise_sample = params[:raise_sample] || 0.5
    raise ArgumentError, "For no good Reason I raised with %#{raise_sample}" if rand > raise_sample
  end
end
