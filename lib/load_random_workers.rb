# frozen_string_literal: true

require 'byebug'

worker_files = Dir[Rails.root.join('app','workers','**','*_worker.rb').to_s]
require_workers = worker_files.map { |path| File.basename(path, '.rb') }
require_workers.each do |worker|
  require worker
end

workers = ObjectSpace.each_object(Class).select do |klass|
  klass.included_modules.include?(Sidekiq::Worker)
end


while true
  workers.each do |worker|
    sleep(0.5)
    puts worker.perform_async
    sleep(0.5)
    puts worker.perform_at((rand*10).hours.from_now)
  end
end

Dir.glob["#{APP_PATH}/app/workers/**/*_worker.rb"]
