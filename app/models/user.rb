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

  include RailsBase::UserConstants

  validate :enforce_owner, if: :will_save_change_to_admin?

  enum admin: ADMIN_ENUMS, _prefix: true

  def self.time_bound
    Time.zone.now - RailsBase.config.auth.mfa_time_duration
  end

  # defines instance methods like
  # user.at_least_super?
  # user.at_least_owner?
  # This is 100% dependent upon keeping ADMIN_ENUMS in order of precedence
  ADMIN_ENUMS.each_with_index do |level, index|
    define_method("at_least_#{level}?") do
      i = ADMIN_ENUMS.find_index(admin.to_sym)
      i >= index
    end
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

  def inspect_name
    "[#{id}]: #{full_name}"
  end

  private

  def enforce_owner
    from, to = admin_change_to_be_saved
    # skip validation event if we are not updating to owner role
    return if to.to_sym != ADMIN_ROLE_OWNER

    # add 1 because we are trying to change the current user to ADMIN_ROLE_OWNER
    count = User.where(admin: ADMIN_ROLE_OWNER).count + 1
    return if count <= RailsBase.config.owner.max

    errors.add(:status, "unable to have more than #{RailsBase.config.owner.max} owner(s).")
  end
end
