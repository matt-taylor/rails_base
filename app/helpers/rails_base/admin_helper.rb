module RailsBase
  module AdminHelper

    SESSION_REASON_BASE = 'admin_random'
    SESSION_REASON_KEY = 'admin_2fa_verify'

    SECOND_MODAL_MAPPING = {
      phone_number: 'rails_base/shared/admin_modify_phone',
      email: 'rails_base/shared/admin_modify_email'
    }

    def paginate_admin_history_range(start:)
      ((AdminAction::DEFAULT_PAGE_RANGE-start)..(start+AdminAction::DEFAULT_PAGE_RANGE))
    end

    def paginante_class_names(curr_page:, page_number:, count_on_page:)
      bootstrap_class = 'disabled' unless paginate_can_view_page?(page_number: page_number, count_on_page: count_on_page)
      bootstrap_class = 'active' if curr_page == page_number
      bootstrap_class || ''
    end

    def paginate_can_view_page?(page_number:, count_on_page:)
      min_size = (page_number-1) * count_on_page
      AdminAction.all.size >= min_size
    end

    def paginate_admin_can_next?(page_number:, count_on_page:)
      min_size = (page_number) * count_on_page
      AdminAction.all.size >= min_size
    end

    def paginate_admin_can_prev?(page_number:, count_on_page:)
      return false if (page_number - 1) < 1

      min_size = (page_number - 1) * count_on_page
      AdminAction.all.size > min_size
    end

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
