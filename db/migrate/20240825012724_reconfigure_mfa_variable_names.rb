class ReconfigureMfaVariableNames < ActiveRecord::Migration[6.1]
  def change
    ###
    # DELETE THIS FROM THIS MIGRATION -- This gets added to the migration before
    rename_column :users, :otp_required_for_login, :mfa_otp_enabled
    ####

    ## Rename original MFA columns to SMS specific columns
    rename_column :users, :mfa_enabled, :mfa_sms_enabled
    rename_column :users, :last_mfa_login, :last_mfa_sms_login

    # Add new Column for Last time logged in via OTP generated code
    add_column :users, :last_mfa_otp_login, :datetime
  end
end
