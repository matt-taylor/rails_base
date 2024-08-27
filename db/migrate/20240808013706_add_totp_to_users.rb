class AddTotpToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :temp_otp_secret, :string
    add_column :users, :consumed_timestep, :integer
    add_column :users, :mfa_otp_enabled, :boolean, default: false
    add_column :users, :otp_backup_codes, :text
  end
end
