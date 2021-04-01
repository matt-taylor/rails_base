module RailsBase
  class AdminUpdateAttribute < RailsBase::ServiceBase
    delegate :params, to: :context
    delegate :klass_string, to: :context

    def call
      validate_model!
      validate_model_row!

      attribute = validate_attribute!
      original_value = model_row.public_send(attribute)
      begin
        model_row.update_attribute(attribute, sanitized_value)
      rescue StandardError
        context.fail!(message: "Failed to update [#{attribute}] with #{sanitized_value} on #{model}##{model_row.id}")
      end
      context.message = "#{model}##{params[:id]} has changed attribute [#{attribute}] from [#{original_value}]=>#{sanitized_value}"
    end

    def validate!
      raise "Expected params to be a Hash. Received #{params.class}" unless params.is_a? ActionController::Parameters
      raise "Expected params to have a id. Received #{params[:id]}" if params[:id].nil?
      raise "Expected params to have a email. Received #{params[:email]}" if params[:email].nil?
    end
  end
end
