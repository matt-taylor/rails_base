# == Schema Information
#
# Table name: short_lived_data
#
#  id                      :bigint           not null, primary key
#  user_id                 :integer          not null
#  data                    :string(255)      not null
#  reason                  :string(255)
#  death_time              :datetime         not null
#  extra                   :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  exclusive_use_count     :integer          default(0)
#  exclusive_use_count_max :integer
#

class ShortLivedData < ApplicationRecord
  self.table_name = 'short_lived_data'

  DEFAULT_TIME_TO_LIVE = 1.hour.freeze
  LENGTH_OF_HEX = 64.freeze
  MAX_ATTEMPTS = 10.freeze
  VALID_DATA_USE_LENGTH = [:numeric, :alphanumeric, :hex].freeze
  VALID_DATA_NON_LENGTH = [:uuid]
  VALID_DATA_USE = [VALID_DATA_NON_LENGTH, VALID_DATA_USE_LENGTH].flatten.freeze

  class << self
    # ShortLivedData.create_data_key(user: User.first, ttl: 5.hours)
    def create_data_key(user:, max_use: nil, data: nil, data_use: :alphanumeric, expires_at: nil, ttl: DEFAULT_TIME_TO_LIVE, reason: 'default', length: LENGTH_OF_HEX, extra: nil)
      raise ":ttl is expected to be an ActiveSupport::Duration" unless ttl.is_a?(ActiveSupport::Duration)

      if data.nil?
        data = generate_secure_datum(data_use, length: length)
        attempt = 0
        while get_by_data(data: data, reason: reason)
          Rails.logger.warn "Data key already in use for #{data_use}. Attempt #{attempt} for reason #{reason} for user_id #{user.id}"
          data = generate_secure_hex(data_use, length: length)
          attempt +=1
          raise "Failed to generate unique id. Attempted #{attempt} times" if attempt >= MAX_ATTEMPTS
        end
      end

      # expires at takes precedence since this is a dangerous oeration and should only be done with caution
      # dangerous because of time zone checks --- we dont do that
      death_time = Time.now + ttl
      death_time = expires_at if expires_at

      create(user_id: user.id, data: data, death_time: death_time, reason: reason, extra: extra, exclusive_use_count_max: max_use)
    end

    def get_by_data(data:, reason: nil)
      # data is indexed and uniq
      params = { data: data, reason: reason }.compact
      where(params).first
    end

    def generate_secure_datum(data_use, length: LENGTH_OF_HEX)
      case data_use.to_sym
      when :numeric
        return rand.to_s[2..(2+(length-1))]
      when *VALID_DATA_USE_LENGTH
        return SecureRandom.public_send(data_use, length)
      when *VALID_DATA_NON_LENGTH
        return SecureRandom.public_send(data_use)
      else
        raise ArgumentError, "Unexpected data_use: Expected #{VALID_DATA_USE}. given [#{data_use}]"
      end
    end

    def find_datum(data:, reason: nil, access_count: true)
      datum = get_by_data(data: data, reason: reason)

      params = {
        user: datum&.user,
        use_count: datum&.exclusive_use_count,
        max_use_count: datum&.exclusive_use_count_max,
        valid: datum&.is_valid? || false,
        invalid_reason: datum&.invalid_reason || ['Forbidden. Invalid usecase'],
        found: !datum.nil?,
        extra: datum&.extra,
        access_count_proc: -> { datum&.add_access_count! }
      }
      datum&.add_access_count! if access_count

      return params unless params[:valid]

      if reason && (datum&.reason.to_sym != reason.to_sym)
        params[:valid] = false
        params[:invalid_reason] = ['Unknown reason for datum field']
      end

      params
    end
  end

  def add_access_count!
    # only update if count is valid and we can add things -- save db call
    return false unless used_count_valid?

    update_attributes(exclusive_use_count: exclusive_use_count + 1)
  end

  def invalid_reason
    arr = []
    arr << 'too many uses' unless used_count_valid?
    arr << 'expired' unless still_alive?
    arr
  end

  def is_valid?
    used_count_valid? && still_alive?
  end

  def still_alive?
    (death_time).to_f > Time.now.to_f
  end

  def used_count_valid?
    return true if exclusive_use_count_max.nil?

    return exclusive_use_count < exclusive_use_count_max
  end

  def user
    @user ||= User.find(user_id)
  end

  def user=(u)
    update_attributes(user_id: u.id)
    u.id
  end
end
