# == Schema Information
#
# Table name: secrets
#
#  id         :bigint           not null, primary key
#  version    :integer
#  secret     :text(65535)
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Secret < ApplicationRecord
  class << self
    def update(name:, secret:)
      next_version = get_secrets(name: name).select(:version).last&.version || 0
      next_version += 1 # always increase the version

      instance = new(version: next_version, name: name, secret: secret)
      instance.save!

      instance
    end

    def get_current_secret(name:)
      get_secrets(name: name).last
    end

    def get_secret_range(name:, range: [-2..-1])
      where(name: name)[*range]
    end

    def get_secrets(name:)
      where(name: name)
    end
  end
end
