module RailsBase::UserSettingsHelper
  CONFIRM_PASSWORD_FLOW = {
    password_flow: 'rails_base/user_settings/modify_password_update_password',
    destroy_user: 'rails_base/user_settings/confirm_destroy_user'
  }

  DATUM_LENGTH = 36
  DATUM_TTL = 30.seconds
  DATUM_REASON = :confirm_password


  def datum
    params = {
      user: current_user,
      max_use: 1,
      reason: DATUM_REASON,
      ttl: DATUM_TTL,
      length: DATUM_LENGTH,
    }
    ShortLivedData.create_data_key(**params)
  end
end
