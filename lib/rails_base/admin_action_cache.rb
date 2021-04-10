require 'redis'
require 'redis-namespace'
require 'json'

module RailsBase
  class AdminActionCache
    include Singleton

    KEY_BASE = 'aac_user'
    LAST_VIEWED_BASE = 'lv'
    LV_TTL = 150.days
    TTL_FOR_CACHE = 60.days
    VALID_TIME_OBJECT = [Time, DateTime, ActiveSupport::TimeWithZone]

    attr_reader :redis

    def initialize
      url = RailsBase.config.redis.admin_action
      namespace = RailsBase.config.redis.admin_action_namespace
      client = Redis.new(url: url)
      @redis = Redis::Namespace.new(namespace, redis_url: client)
      @logger = Rails.logger
    end

    def add_action(user:, msg:, occured:)
      validate!(user, msg, occured)

      score = occured.to_f
      @logger.info { "Adding Redis Cache Admin actions for #{key(user)}" }

      redis.zadd(key(user), score, msg)
      redis.expire(key(user), TTL_FOR_CACHE.to_i)
    end

    def actions_since(user:, alltime: false, time: nil)
      score =
        if alltime
          0
        else
          valid_time!(time)
          score = time.to_f
        end

      validate_user!(user)
      max_score = Time.now.to_f
      @logger.info { "Retrieving Redis Cache Admin actions for #{key(user)} since #{time}" }

      redis.zrangebyscore(key(user), score, max_score, with_scores: true)
    end

    def delete_actions_since!(user:, time:)
      valid_time!(time)
      validate_user!(user)

      score = time.to_f
      redis.zremrangebyscore(key(user), 0, score)
      @logger.info { "Deleted Redis Cache Admin actions for #{key(user)}" }
      true
    end

    def update_last_viewed(user:, time: Time.zone.now)
      valid_time!(time)
      validate_user!(user)

      redis.set(key_last_viewed(user), time.to_f, ex: LV_TTL)
    end

    def get_last_viewed(user:)
      validate_user!(user)

      redis.get(key_last_viewed(user))
    end

    private

    def validate!(user, msg, occured)
      raise ArgumentError, 'Expected msg to be a string' unless msg.is_a?(String)

      validate_user!(user)
      valid_time!(occured)
    end

    def validate_user!(user)
      raise ArgumentError, 'Expected user to respond to `id`' unless user.respond_to?('id')
    end

    def valid_time!(time)
      raise ArgumentError, "Expected occured to be a #{VALID_TIME_OBJECT.join(' or ')}" unless VALID_TIME_OBJECT.include?(time.class)
    end

    def key_last_viewed(user)
      "#{key(user)}:#{LAST_VIEWED_BASE}"
    end

    def key(user)
      "#{KEY_BASE}:#{user.id}"
    end
  end
end
