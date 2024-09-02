# frozen_string_literal: true

module RailsBase::Mfa::Strategy
  class Base < RailsBase::ServiceBase
    delegate :user, to: :context
    delegate :force, to: :context
    delegate :mfa_type, to: :context
    delegate :mfa_last_used, to: :context

    def call
      log(level: :info, msg: "#{user_prepend} : MFA strategy against #{mfa_type}")

      if require_mfa?(user: user, mfa_type: mfa_type, mfa_last_used: mfa_last_used)
        mfa_required
      else
        if force
          log(level: :info, msg: "#{user_prepend} : MFA strategy was not required at this time. However -- Force option was passed in")
          mfa_required
        else
          mfa_not_required
        end
      end
    end

    def mfa_required
      log(level: :info, msg: "#{user_prepend} : MFA strategy is required at this time based on the strategy")
      context.request_mfa = true
    end

    def mfa_not_required
      log(level: :info, msg: "#{user_prepend} : MFA strategy is NOT required at this time")
      context.request_mfa = false
    end

    def user_prepend
      "[#{user.full_name} (#{user.id})]"
    end

    def validate!
      raise "Expected user to be a User. Received #{user.class}" unless User === user
      raise "Expected mfa_type to be a present" if mfa_type.nil?
    end
  end
end
