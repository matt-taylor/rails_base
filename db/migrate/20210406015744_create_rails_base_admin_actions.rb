class CreateRailsBaseAdminActions < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_actions do |t|
      t.bigint :admin_user_id, null: false
      t.bigint :user_id
      t.string :action       , null: false
      t.string :change_from
      t.string :change_to
      t.text   :long_action

      t.timestamps
    end

    add_index :admin_actions, :admin_user_id
    add_index :admin_actions, :user_id
  end
end
