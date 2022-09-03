module RailsBase
  module Configuration
    class Base
      class InvalidConfiguration < StandardError; end;
      class InvalidCustomConfiguration < StandardError; end;
      class ConfigurationAlreadyEstablished < StandardError; end;

      def self._allow_write_block?
        true
      end

      def self._unset_allow_write!
        define_singleton_method('_allow_write_block?') do
          false
        end
      end

      ALLOWED_TYPES = {
        array: -> (val) { [Array].include?(val.class) },
        array_nil: -> (val) { [Array, NilClass].include?(val.class) },
        boolean: -> (val) { [TrueClass, FalseClass].include?(val.class) },
        duration: -> (val) { [ActiveSupport::Duration].include?(val.class) },
        hash: -> (val) { [Hash].include?(val.class) },
        integer: -> (val) { [Integer].include?(val.class) },
        klass: -> (_val) { true },
        path: -> (val) { [Pathname].include?(val.class) },
        proc: -> (val) { [Proc].include?(val.class) },
        string: -> (val) { [String].include?(val.class) },
        string_nil: -> (val) { [String, NilClass].include?(val.class) },
        string_proc: -> (val) { [String, Proc].include?(val.class) },
        symbol: -> (val) { [Symbol].include?(val.class) },
        symbol_class: -> (val) { [Symbol].include?(val.class) || val.superclass === ActiveJob::QueueAdapters },
        values: -> (_val) { true },
      }

      def initialize
        override_methods!
        assign_default_values!
        def_convenience_methods
      end

      # on any object you Base inherited object yoyu can call
      # `.dig(:chain1, :chain2, :chain3)
      def dig(*args, default: nil, &block)
        current = self.public_send(args[0])

        args[1..-1].each do |key|
          return current || default if current.nil?

          current = current.public_send(key)
        end
        current
      rescue StandardError
        if block_given?
          yield block
        else
          default
        end
      end

      def assign_default_values!
        self.class::DEFAULT_VALUES.each do |key, object|
          val = object[:default_assign_on_boot] ? object[:default_assign_on_boot].call : object[:default]
          public_send(:"#{key}=", val)
        end
        true
      end

      def override_methods!
        self.class::DEFAULT_VALUES.each do |key, object|
          self.class.define_method(:"#{key}=") do |value|
            raise ConfigurationAlreadyEstablished, "Unable to assign [#{_name}.#{key}]. Assignment must happen on boot" unless self.class._allow_write_block?

            instance_variable_set(:"@#{key}", value)
          end
          if object[:type] == :array
            self.class.define_method(:"#{key}<<") do |value|
              raise ConfigurationAlreadyEstablished, "Unable to assign [#{_name}.#{key}]. Assignment must happen on boot" unless self.class._allow_write_block?

              curr = instance_variable_get(:"@#{key}")
              curr << value
              instance_variable_set(:"@#{key}", curr)
            end
          end
          if object[:type] == :hash
            self.class.define_method(:"#{key}.merge") do |value|
              raise ConfigurationAlreadyEstablished, "Unable to assign [#{_name}.#{key}]. Assignment must happen on boot" unless self.class._allow_write_block?

              curr = instance_variable_get(:"@#{key}")
              curr.merge(value)
              instance_variable_set(:"@#{key}", curr)
            end
          end
        end
      end

      def validate!
        custom_validations
        self.class::DEFAULT_VALUES.each do |key, object|
          value = instance_variable_get("@#{key}".to_sym)
          validate_var!(key: key, var: value, type: object[:type])
          validate_custom_rule!(var: value, custom: object[:custom], key: key, msg: object[:msg])
          validate_klass_type!(key: key, var: value, type: object[:type], klass_type: object[:klass_type])
          validate_values_included!(key: key, var: value, type: object[:type], expect_values: object[:expect_values])
          if object[:on_assignment]
            if object[:on_assignment].is_a? Array
              object[:on_assignment].each do |elem|
                elem.call(value, self)
              end
            else
              object[:on_assignment].call(value, self)
            end
          end
        end
        true
      end

      private

      def custom_validations; end

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
          elsif object[:type] == :string_proc
            self.class.define_method("#{key}") do |*args|
              return false unless dependents_true?(key)

              if instance_variable_get("@#{key}".to_sym).is_a? Proc
                instance_variable_get("@#{key}".to_sym).call(args[0])
              else
                instance_variable_get("@#{key}".to_sym)
              end
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

        raise InvalidConfiguration, "#{_name}.#{key} expects a #{type}."
      end

      def validate_klass_type!(var:, type:, key:, klass_type:)
        return if klass_type.nil?

        boolean =
          if var.is_a? Array
            var.all? { |s| klass_type.include?(s.class) }
          else
            klass_type.include?(var.class)
          end
        return if boolean

        raise InvalidConfiguration, "#{_name}.#{key} expects all members to be a #{klass_type}. Received: [#{var.class}]"
      end

      def validate_values_included!(key:, var:, type:, expect_values:)
        return if expect_values.nil?
        values =
          if expect_values.is_a? Proc
            expect_values.call(self)
          else
            expect_values
          end

        return if values.include?(var)

        raise InvalidConfiguration, "#{_name}.#{key} expects value to be included in [#{values}]. Received: [#{var}]"
      end

      def _name
        self.class.name.demodulize
      end

      def validate_custom_rule!(var:, custom:, key:, msg:)
        return if custom.nil?
        return if custom.call(var)

        raise InvalidCustomConfiguration, msg
      end
    end
  end
end
