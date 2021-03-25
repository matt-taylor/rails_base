class CreateRailsBaseSecrets < ActiveRecord::Migration[5.2]
  def change
    create_table :secrets do |t|
      t.integer :version
      t.text :secret
      t.string :name

      t.timestamps
    end
  end
end
