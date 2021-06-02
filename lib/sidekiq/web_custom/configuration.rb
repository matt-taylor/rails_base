require 'byebug'

module Sidekiq
  module WebCustom
    class Configuration

      ALLOWED_BASED = [:actions, :local_erbs]
      INTEGERS = [:drain_rate, :max_execution_time, :warn_execution_time]

      DEFAULT_DRAIN_RATE = 10
      DEFAULT_EXEC_TIME = 6
      DEFAULT_WARN_TIME = 5
      attr_reader *ALLOWED_BASED

      attr_accessor *INTEGERS

      def initialize
        ALLOWED_BASED.each do |var|
          instance_variable_set(:"@#{var}", {})
        end

        @drain_rate = DEFAULT_DRAIN_RATE
        @max_execution_time = DEFAULT_EXEC_TIME
        @warn_execution_time = DEFAULT_WARN_TIME
      end

      def actions
        @actions
      end

      def local_erbs
        @local_erbs
      end

      INTEGERS.each do |int|
        define_singleton_method("#{int}=") do |val|
          raise Sidekiq::WebCustom::ArgumentError, "Expected #{int} to be an integer" unless val.is_a?(Integer)

          super(val)
        end
      end

      def drain_rate=(int)


        super(int)
      end

      def merge(base:, params:)
        raise Sidekiq::WebCustom::ArgumentError, "Unexpected base: #{base}" unless ALLOWED_BASED.include?(base)
        raise Sidekiq::WebCustom::ArgumentError, "Expected object for #{base} to be a Hash" unless params.is_a?(Hash)

        value = instance_variable_get(:"@#{base}")
        instance_variable_set(:"@#{base}", value.merge(params))
      end

      def validate!
        ALLOWED_BASED.each do |key|
          value = instance_variable_get(:"@#{key}")
          _validate!(value, key)
        end

        return true if @warn_execution_time <= @max_execution_time

        raise Sidekiq::WebCustom::ArgumentError, "Expected warn_execution_time to be less than max_execution_time"
      end

      private

      def _validate!(params, key)
        params.each do |k, file|
          next if File.exist?(file)

          raise Sidekiq::WebCustom::FileNotFound,
            "#{key}.merge passed #{k}: #{file}.\n" \
            "The absolute file path does not exist."
        end
      end
    end
  end
end
