# == Schema Information
#
# Table name: admin_actions
#
#  id            :bigint           not null, primary key
#  admin_user_id :bigint           not null
#  user_id       :bigint
#  action        :string(255)      not null
#  change_from   :string(255)
#  change_to     :string(255)
#  long_action   :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class AdminAction < ApplicationRecord
  DEFAULT_PAGE_COUNT = 5
  DEFAULT_PAGE_COUNT_SELECT_RANGE = (0..100).select { |x| x%5 == 0 && x != 0 }
  DEFAULT_PAGE_RANGE = 2

  class << self
    def action(admin_user:, action:, user: nil, change_from: nil, change_to: nil, long_action: nil)
      params = { admin_user_id: admin_user.id, action: action }
      params[:user_id] = user.id if user
      params[:change_from] = change_from if change_from
      params[:change_to] = change_to if change_to
      params[:long_action] = long_action if long_action
      begin
        AdminAction.create!(params)
      rescue StandardError => e
        Rails.logger.error(e.message)
        Rails.logger.error("Unable to save admin action [#{action}]: [#{params}]")
        nil
      end
    end

    def repopulate_cache(max_items: 1000)
    end

    def paginate_records(page:, count_on_page: DEFAULT_PAGE_COUNT)
      offset = (page - 1) * count_on_page
      order(created_at: :desc).offset(offset).limit(count_on_page)
    end
  end

  def admin_user
    @admin_user ||= User.find admin_user_id
  end

  def user
    @user ||= User.find user_id
  end

  def readable(long: false)
    msg = "Admin [#{admin.full_name}(#{admin_user_id})]: #{ long ? long_action : long}."
    msg = "Changed from [#{change_from}]."if change_from
    msg = "Changed To [#{change_to}]."if change_to
    msg = "Occured at #{created_at}"
    msg
  end

  private

end

