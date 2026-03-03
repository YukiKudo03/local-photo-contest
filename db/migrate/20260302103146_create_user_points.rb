class CreateUserPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :user_points do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :points, null: false
      t.string :action_type, null: false
      t.string :source_type
      t.integer :source_id
      t.json :metadata, default: {}
      t.datetime :earned_at, null: false

      t.timestamps
    end

    add_index :user_points, [ :user_id, :earned_at ]
    add_index :user_points, [ :user_id, :action_type ]
    add_index :user_points, [ :source_type, :source_id ]
  end
end
