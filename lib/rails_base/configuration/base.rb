module RailsBase
  module Configuration
    class Base
      class InvalidConfiguration < StandardError; end;
      class InvalidCustomConfiguration < StandardError; end;

      ALLOWED_TYPES = {
        boolean: -> (val) { [TrueClass, FalseClass].include?(val.class) },
        proc: -> (val) { [Proc].include?(val.class) },
        integer: -> (val) { [Integer].include?(val.class) },
        string: -> (val) { [String].include?(val.class) },
        duration: -> (val) { [ActiveSupport::Duration].include?(val.class) },
        string_nil: -> (val) { [String, NilClass].include?(val.class) },
      }

      def initialize
        assign_default_values!
        def_convenience_methods
      end

      def assign_default_values!
        self.class::DEFAULT_VALUES.each do |key, object|
          public_send(:"#{key}=", object[:default])
        end
        true
      end

      def validate!
        custom_validations
        self.class::DEFAULT_VALUES.each do |key, object|
          value = instance_variable_get("@#{key}".to_sym)
          validate_var!(key: key, var: value, type: object[:type])
          validate_custom_rule!(var: value, custom: object[:custom], key: key, msg: object[:msg])
          if object[:on_assignment]
            object[:on_assignment].call(value)
          end
        end
        true
      end

      private

      def custom_validations
      end

      def def_convenience_methods
        self.class::DEFAULT_VALUES.each do |key, object|
          if object[:type] == :boolean
            self.class.define_method("#{key}?") do
              return false unless dependents_true?(key)

              public_send(key)
            end
          elsif object[:type] == :proc
            self.class.define_method("#{key}?") do |current_user|
              return false unless dependents_true?(key)

              public_send(key).call(current_user)
            end
          else
            self.class.define_method("#{key}") do
              return false unless dependents_true?(key)

              instance_variable_get("@#{key}".to_sym)
            end
          end
        end
      end

      def dependents_true?(key)
        dependents = self.class::DEFAULT_VALUES[key][:dependents] || []

        dependents.all? { |s| s.call(self) }
      end

      def validate_var!(var:,  type:, key:)
        proc = ALLOWED_TYPES.fetch(type)
        return if proc.call(var)

        raise InvalidConfiguration, "#{key} expects a #{type}."
      end

      def validate_custom_rule!(var:, custom:, key:, msg:)
        return if custom.nil?
        return if custom.call(var)

        raise InvalidCustomConfiguration, msg
      end
    end
  end
end
