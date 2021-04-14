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
    include ActionView::Helpers::DateHelper
    def action(admin_user:, action:, user: nil, original_attribute: nil, new_attribute: nil, long_action: nil)
      params = { admin_user_id: admin_user.id, action: action }
      params[:user_id] = user.id if user
      params[:change_from] = original_attribute.to_s unless original_attribute.nil?
      params[:change_to] = new_attribute.to_s unless new_attribute.nil?
      params[:long_action] = long_action unless long_action.nil?
      begin
        instance = AdminAction.create!(params)
        ship_to_cache!(instance: instance, user: user, created_at: Time.zone.now) if user
        instance
      rescue StandardError => e
        Rails.logger.error(e.message)
        Rails.logger.error("Unable to save admin action [#{action}]: [#{params}]")
        nil
      end
    end

    def repopulate_cache!(max_items: 1000)
      objects = order(created_at: :desc).where.not(user_id: nil).limit(max_items)
      count = 0
      objects.in_batches(of: 500) do |group|
        group.each do |instance|
          count += 1
          user = instance.user
          msg = instance.readable(with_occurred: false)
          RailsBase::Admin::ActionCache.instance.add_action(user: user, msg: msg, occured: instance.created_at)
        end
      end
      count
    end

    def get_cache_items(user:, time: Time.zone.now, use_lv: false, alltime: false, delete: false, update_lv: false)
      if use_lv
        Rails.logger.warn { "Using Last Viewed admin actions for user #{user.id}" }
        temp = RailsBase::Admin::ActionCache.instance.get_last_viewed(user: user)
        time = temp.nil? ? time : (Time.at(temp) rescue time)
      end

      objects = RailsBase::Admin::ActionCache.instance.actions_since(user: user, time: time, alltime: alltime)

      admin_messages = objects.map do |object|
        msg = object[0]
        in_words = distance_of_time_in_words(Time.zone.now, object[1], include_seconds: true)
        [msg, "~ #{in_words.humanize} ago"]
      end

      if delete
        Rails.logger.warn { "Deleting admin actions for user #{user.id}" }
        RailsBase::Admin::ActionCache.instance.delete_actions_since!(user: user, time: time)
      end

      if update_lv
        Rails.logger.warn { "Udating Last Viewed admin actions for user #{user.id}" }
        RailsBase::Admin::ActionCache.instance.update_last_viewed(user: user, time: time)
      end

      admin_messages
    end

    def ship_to_cache!(instance:, user:, created_at: nil)
      msg = instance.readable(with_occurred: false)
      RailsBase::Admin::ActionCache.instance.add_action(user: user, msg: msg, occured: instance.created_at)
    end

    def paginate_records(page:, user_id: nil, admin_id: nil, count_on_page: DEFAULT_PAGE_COUNT, count: false)
      params = {}
      params[:user_id] = user_id if user_id && user_id.positive?
      params[:admin_user_id] = admin_id if admin_id && admin_id.positive?
      offset = (page - 1) * count_on_page
      puts "using params: #{params}"
      if count
        where(params).count
      else
        where(params).order(created_at: :desc).offset(offset).limit(count_on_page)
      end
    end
  end

  def admin_user
    @admin_user ||= User.find admin_user_id
  end

  def user
    @user ||= user_id ? User.find(user_id) : nil
  end

  def readable(long: false, with_occurred: true)
    msg = "[#{admin_user.full_name}(#{admin_user_id})]: #{ long ? long_action : action}."
    msg += " Changed from [#{change_from}]." unless change_from.nil?
    msg += " Changed to [#{change_to}]." unless change_to.nil?
    msg += " Occured at #{created_at}." if with_occurred
    msg
  end

  private

end

