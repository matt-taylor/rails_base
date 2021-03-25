class CreateRailsBaseShortLivedData < ActiveRecord::Migration[5.2]
  def change
    create_table :short_lived_data do |t|

      t.integer :user_id, null: false
      t.string :data, null: false
      t.string :reason
      t.datetime :death_time, null: false
      t.string :extra
      t.integer :exclusive_use_count, default: 0
      t.integer :exclusive_use_count_max

      t.timestamps
    end

    add_index :short_lived_data, :data
    add_index :short_lived_data, [:data, :reason]
  end
end
