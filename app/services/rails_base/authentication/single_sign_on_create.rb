module RailsBase::Authentication
  class SingleSignOnCreate < RailsBase::ServiceBase
    delegate :user, to: :context
    delegate :token_length, to: :context
    delegate :uses, to: :context
    delegate :expires_at, to: :context
    delegate :reason, to: :context
    delegate :token_type, to: :context
    delegate :url_redirect, to: :context

    def call
      msg = "Creating SSO token [#{reason}]: user_id:#{user.id}; "\
        "uses:#{uses.nil? ? 'unlimited' : uses}; expires_at:#{expires_at}"
      log(level: :info, msg: msg)
      context.data = create_sso_token
    end

    def create_sso_token
      params = {
        user: user,
        max_use: uses,
        data_use: data_type,
        expires_at: expires_at,
        reason: reason,
        length: token_length,
        extra: url_redirect,
      }.compact
      ShortLivedData.create_data_key(**params)
    end

    def data_type
      ShortLivedData::VALID_DATA_USE_LENGTH.include?(token_type&.to_sym) ? token_type.to_sym : nil
    end

    def validate!
      raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
      raise "Expected token_length to be a Int. Received #{token_length.class}" unless token_length.is_a? Integer
      raise "Expected reason to be present." if reason.nil?

      time_class = ActiveSupport::TimeWithZone
      raise "Expected expires_at to be a Received #{time_class}. Received #{expires_at.class}" unless expires_at.is_a? time_class
    end
  end
end
