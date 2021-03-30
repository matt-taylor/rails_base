class AddActiveAndEnumColsToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :admin, :integer, default: 0
    add_column :users, :active, :boolean, default: true
  end
end
