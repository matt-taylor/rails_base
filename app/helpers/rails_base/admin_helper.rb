module RailsBase
  module AdminHelper

    SESSION_REASON_BASE = 'admin_random'
    SESSION_REASON_KEY = 'admin_2fa_verify'

    SECOND_MODAL_MAPPING = {
      phone_number: 'rails_base/shared/admin_modify_phone',
      email: 'rails_base/shared/admin_modify_email'
    }

    def users_for_proc(proc)
      User.all.select do |user|
        proc.call(user)
      end.map(&:inspect_name)
    end

    def array_for_proc(proc, array)
      array.map do |instance|
        proc.call(instance)
      end
    end

    def paginated_records
      AdminAction.paginate_records(page: @starting_page, count_on_page: @count_on_page, user_id: @starting_user[1], admin_id: @starting_admin[1])
    end

    def fullsized_paginated_count
      AdminAction.paginate_records(page: @starting_page, count_on_page: @count_on_page, user_id: @starting_user[1], admin_id: @starting_admin[1], count: true)
    end

    def paginate_admin_what_page
      return params[:page].to_i if params[:pagination_count].to_i == params[:prev_count].to_i

      prev_page = params[:prev_page].to_i > 0 ? (params[:prev_page].to_i - 1) : 1
      start_prev = prev_page * params[:prev_count].to_i
      page = (start_prev / params[:pagination_count].to_i)
      page > 0 ? page : 1
    end

    def paginate_admin_history_range(start:)
      ((start-AdminAction::DEFAULT_PAGE_RANGE)..(start+AdminAction::DEFAULT_PAGE_RANGE))
    end

    def paginante_class_names(curr_page:, page_number:, count_on_page:)
      bootstrap_class = 'disabled' unless paginate_can_view_page?(page_number: page_number, count_on_page: count_on_page)
      bootstrap_class = 'active' if curr_page == page_number
      bootstrap_class || ''
    end

    def paginate_can_view_page?(page_number:, count_on_page:)
      min_size = (page_number-1) * count_on_page
      fullsized_paginated_count >= min_size
    end

    def paginate_admin_can_next?(page_number:, count_on_page:)
      min_size = (page_number) * count_on_page
      fullsized_paginated_count >= min_size
    end

    def paginate_admin_can_prev?(page_number:, count_on_page:)
      return false if (page_number - 1) < 1

      min_size = (page_number - 1) * count_on_page
      fullsized_paginated_count > min_size
    end

    def paginate_get_users_array
      @paginate_get_users_array ||= User.where(active: true).map { |u| [u.full_name, u.id] } << ['All Users', -1]
    end

    def paginate_get_admins_array
      @paginate_get_admins_array ||= User.where.not(admin: :none).map { |u| [u.full_name, u.id] } << ['All Admins', -1]
    end

    def paginate_diff_id?(type:)
      session[:"rails_base_paginate_start_#{type}"] != params[type].to_i
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
