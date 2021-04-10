# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  first_name             :string(255)      default(""), not null
#  last_name              :string(255)      default(""), not null
#  phone_number           :string(255)
#  last_mfa_login         :datetime
#  email_validated        :boolean          default(FALSE)
#  mfa_enabled            :boolean          default(FALSE), not null
#  active                 :boolean          default(TRUE), not null
#  admin                  :integer          default("none"), not null
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable, :trackable

  ADMIN_ENUMS = [
    ADMIN_ROLE_TIER_NONE = :none,
    ADMIN_ROLE_TIER_1 = :view_only,
    ADMIN_ROLE_SUPER = :super
  ]

  enum admin: ADMIN_ENUMS, _prefix: true

  SOFT_DESTROY_PARAMS = {
    mfa_enabled: false,
    email_validated: false,
    last_mfa_login: nil,
    encrypted_password: '',
    phone_number: nil,
  }

  SAFE_AUTOMAGIC_UPGRADE_COLS = [
    :active,
    :admin,
    :email,
    :email_validated,
    :mfa_enabled,
    :phone_number,
  ]

  def self.time_bound
    Time.zone.now - RailsBase.config.auth.mfa_time_duration
  end

  def full_name
  	"#{first_name} #{last_name}"
  end

  def past_mfa_time_duration?
    return true if last_mfa_login.nil?

    last_mfa_login < self.class.time_bound
  end

  def set_last_mfa_login!(time: Time.zone.now)
    update(last_mfa_login: time)
  end

  def masked_phone
    return nil unless phone_number

    "(#{phone_number[0]}**) ****-**#{phone_number[-2..-1]}"
  end

  def soft_destroy_user!
    update(SOFT_DESTROY_PARAMS)
  end

  def destroy_user!
    self.delete
  end
end
