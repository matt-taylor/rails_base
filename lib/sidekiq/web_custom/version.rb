# frozen_string_literal: true

module Sidekiq
  module WebCustom
    MAJOR = 0  # With backwards incompatability. Requires annoucment and update documentation
    MINOR = 1  # With feature launch. Documentation of upgrade is useful via a changelog
    PATCH = 1  # With minor upgrades or patcing a small bug. No changelog necessary
    VERSION = [MAJOR,MINOR,PATCH].join('.')

    def self.get_version
      puts VERSION
    end
  end
end
