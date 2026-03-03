class AddGamificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :total_points, :integer, default: 0, null: false
    add_column :users, :level, :integer, default: 1, null: false
    add_index :users, :total_points
    add_index :users, :level
  end
end
