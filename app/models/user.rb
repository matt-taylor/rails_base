# == Schema Information
#
# Table name: users
#
#  id                         :bigint           not null, primary key
#  first_name                 :string(255)      default(""), not null
#  last_name                  :string(255)      default(""), not null
#  phone_number               :string(255)
#  last_mfa_sms_login         :datetime
#  email_validated            :boolean          default(FALSE)
#  mfa_sms_enabled            :boolean          default(FALSE), not null
#  active                     :boolean          default(TRUE), not null
#  admin                      :string(255)
#  last_known_timezone        :string(255)
#  last_known_timezone_update :datetime
#  email                      :string(255)      default(""), not null
#  encrypted_password         :string(255)      default(""), not null
#  reset_password_token       :string(255)
#  reset_password_sent_at     :datetime
#  remember_created_at        :datetime
#  sign_in_count              :integer          default(0), not null
#  current_sign_in_at         :datetime
#  last_sign_in_at            :datetime
#  current_sign_in_ip         :string(255)
#  last_sign_in_ip            :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  otp_secret                 :string(255)
#  temp_otp_secret            :string(255)
#  consumed_timestep          :integer
#  mfa_otp_enabled            :boolean          default(FALSE)
#  otp_backup_codes           :text(65535)
#  last_mfa_otp_login         :datetime
#
class User < RailsBase::ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable, :trackable

  include RailsBase::UserConstants
  include RailsBase::UserHelper::Totp

  validate :enforce_owner, if: :will_save_change_to_admin?
  validate :enforce_admin_type, if: :will_save_change_to_admin?

  def self._def_admin_convenience_method!(admin_method:)
    types = RailsBase.config.admin.admin_types
    #### methods on the instance
    define_method("at_least_#{admin_method}?") do
      i = types.find_index(admin.to_sym)
      i >= types.find_index(admin_method.to_sym)
    end

    define_method("admin_#{admin_method}?") do
      admin.to_sym == admin_method
    end

    define_method("admin_#{admin_method}!") do
      update!(admin: admin_method)
    end

    #### metods on the class
    define_singleton_method("admin_#{admin_method}s") do
      where(admin: admin_method)
    end

    define_singleton_method("admin_#{admin_method}") do
      arr = [admin_method]
      arr = [admin_method, '', nil] if ADMIN_ROLE_NONE == admin_method
      where(admin: arr)
    end
  end

  def self.masked_number(phone_number)
    return nil unless phone_number

    "(#{phone_number[0]}**) ****-**#{phone_number[-2..-1]}"
  end

  def self.readable_phone_number(phone_number)
    return nil unless phone_number

    "(#{phone_number[0..2]}) #{phone_number[3..5]}-#{phone_number[6..-1]}"
  end

  def admin
    (self[:admin].presence || ADMIN_ROLE_NONE).to_sym
  end

  def full_name
  	"#{first_name} #{last_name}"
  end

  def set_last_mfa_sms_login!(time: Time.zone.now)
    update(last_mfa_sms_login: time)
  end

  def set_last_mfa_otp_login!(time: Time.zone.now)
    update(last_mfa_otp_login: time)
  end

  def masked_phone
    User.masked_number(phone_number)
  end

  def readable_phone
     User.readable_phone_number(phone_number)
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

  def update_tz(tz_name:)
    return if last_known_timezone == tz_name

    Rails.logger.info { "#{id}: Setting tz_name: #{tz_name}"  }
    update(last_known_timezone: tz_name, last_known_timezone_update: Time.now )
  end

  def timezone
    RailsBase.config.user.user_timezone(self)
  end

  def convert_time(time:)
    time.in_time_zone(timezone)
  end

  private

  def enforce_admin_type
    from, to = admin_change_to_be_saved
    return if RailsBase.config.admin.admin_types.include?(to.to_sym)

    errors.add(:admin, "Undefined admin type. Expected #{RailsBase.config.admin.admin_types}. Given #{to}")
  end

  def enforce_owner
    from, to = admin_change_to_be_saved
    # skip validation event if we are not updating to owner role
    return if to.to_sym != ADMIN_ROLE_OWNER

    # add 1 because we are trying to change the current user to ADMIN_ROLE_OWNER
    count = User.where(admin: ADMIN_ROLE_OWNER).count + 1
    return if count <= RailsBase.config.owner.max

    errors.add(:admin, "unable to have more than #{RailsBase.config.owner.max} owner(s).")
  end
end
