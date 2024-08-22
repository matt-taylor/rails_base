# frozen_string_literal: true

require "rotp"

####
#
# Copied with love from https://github.com/devise-two-factor/devise-two-factor
#
####

module RailsBase
  module UserHelper
    module Totp
      extend ActiveSupport::Concern

      class Error < StandardError; end
      class NotRequired < Error; end

      included do
        serialize :otp_backup_codes, Array
      end

      def self.included(base)
        base.include(ConsumeMethodOptions)
        base.include(BackupMethodOptions)
        base.extend(ClassOptions)
      end

      def reset_otp!
        self.otp_secret = nil
        self.temp_otp_secret = nil
        self.consumed_timestep = nil
        self.otp_required_for_login = false
        self.otp_backup_codes = []

        save!
      end
    end
  end
end
