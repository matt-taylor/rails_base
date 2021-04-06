module RailsBase
  module AdminHelper

    SESSION_REASON_BASE = 'admin_random'
    SESSION_REASON_KEY = 'admin_2fa_verify'

    SECOND_MODAL_MAPPING = {
      phone_number: 'rails_base/shared/admin_modify_phone',
      email: 'rails_base/shared/admin_modify_email'
    }

    def accurate_admin_user
      session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY] ||
        current_user.id
    end

    def admin_user
      @admin_user ||= User.find(accurate_admin_user)
    end

    def session_reason
      session[SESSION_REASON_KEY]
    end

    def parse_mfa_to_obj
      arr = []
      params[:mfa_input].split('').each_with_index do |code, i|
        arr << ["#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{i}", code]
      end
      { mfa: arr.to_h.symbolize_keys }
    end
  end
end
