module RailsBase
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    def self._magically_defined_time_objects
      columns.each do |column|
        next unless [:datetime].include?(column.type)

        # This is actually pretty cool. If you set the thrad corectly, you can
        define_method("#{column.name}") do
          thread_tz = Thread.current[RailsBase::ApplicationController::TIMEZONE_THREAD_NAME]
          return super() if thread_tz.nil?
          time = self[column.name].in_time_zone(thread_tz) rescue self[column.name]

          Rails.logger.debug { "#{self.class.name}.#{column.name} intercepted :datetime [#{self[column.name]}] and returned [#{time}] - tz[#{thread_tz}]" }

          time
        end
      end
    end
  end
end