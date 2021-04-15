module RailsBase
  class AdminUpdateAttribute < RailsBase::ServiceBase
    delegate :params, to: :context
    delegate :klass_string, to: :context
    delegate :admin_user, to: :context

    def call
      validate_model!
      validate_model_row!

      attribute = validate_attribute!
      validate_permission!
      fail_attribute!(attribute: attribute)

      original_value = model_row.public_send(attribute)
      begin
        model_row.update_attributes!(attribute => sanitized_value)
      rescue ActiveRecord::RecordInvalid => e
        context.fail!(message: "Failed to update [#{attribute}] with #{sanitized_value} on #{model}##{model_row.id}. #{e.message}")
      rescue StandardError
        context.fail!(message: "Failed to update [#{attribute}] with #{sanitized_value} on #{model}##{model_row.id}")
      end
      context.attribute = sanitized_value
      context.original_attribute = original_value
      context.model = model_row
      context.message = "#{model}##{params[:id]} has changed attribute [#{attribute}] from [#{original_value}]=>#{sanitized_value}"
    end

    def fail_attribute!(attribute:)
      if params[:_fail_].present?
        log(level: :warn, msg: "FAIL param passed in. Automagic failure for admin update")
        context.fail!(message: "Failed to update [#{attribute}] with #{sanitized_value} on #{model}##{model_row.id}")
      end
    end

    def validate_permission!
      proc = model::SAFE_AUTOMAGIC_UPGRADE_COLS[attribute]
      return if proc.call

      context.fail!(message: "User does not have permissions to update #{attribute}")
    end

    def validate_attribute!
      attribute = params[:attribute].to_sym
      unless model::SAFE_AUTOMAGIC_UPGRADE_COLS.keys.include?(attribute)
        context.fail!(message: "#{attribute} is not part of allowed updatable columns")
      end
      attribute
    end

    def sanitized_value
      case params[:value]
      when 'true'
        true
      when 'false'
        false
      else
        params[:value]
      end
    end

    def model
      @model ||= klass_string ? klass_string.constantize : User
    end

    def model_row
      @model_row ||= model.find(params[:id])
    end

    def validate_model_row!
      return if model_row

      context.fail!(message: "Failed to find id:#{params[:id]} on model: #{model}")
    end

    def validate_model!
      begin
        model
      rescue StandardError
        context.fail!(message: "Failed to find model")
      end

      begin
        model::SAFE_AUTOMAGIC_UPGRADE_COLS
      rescue StandardError
        context.fail!(message: "#{model}::SAFE_AUTOMAGIC_UPGRADE_COLS array does not exist")
      end
    end

    def validate!
      raise "Expected params to be a Hash. Received #{params.class}" unless params.is_a? ActionController::Parameters
      raise "Expected params to have a id. Received #{params[:id]}" if params[:id].nil?
      raise "Expected admin_user." if admin_user.nil?
    end
  end
end
