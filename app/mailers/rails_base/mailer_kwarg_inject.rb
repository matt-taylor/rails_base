module RailsBase::MailerKwargInject

  def self.included(base)
    base.extend(ClassMethods)
    base.inject_safety_net!
  end

  module ClassMethods
    def inject_safety_net!
      action_methods.each do |method_name|
        alias_method_name = "__rails_base__kwarg_inject_#{method_name}__"
        self.alias_method(alias_method_name, method_name)

        self.define_method(method_name) do |*args, **kwargs, &block|
          parameter_name_order = method(alias_method_name).parameters.map(&:second)
          begin
            self.send(alias_method_name, *args, **kwargs, &block)
          rescue ArgumentError => e
            if Hash === args[0]
              new_arg_list = parameter_name_order.map { args[0][_1] }
              self.send(alias_method_name, *new_arg_list, &block)
              ActiveSupport::Deprecation.warn("Method Signature of `#{self.class}.#{method_name}` will change from KWargs to ARGs. Please modify your code.")
            else
              raise
            end
          end
        end
      end
    end
  end
end
