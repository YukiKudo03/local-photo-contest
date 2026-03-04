class CreateReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :reactions do |t|
      t.integer :user_id, null: false
      t.integer :entry_id, null: false
      t.string :reaction_type, limit: 20, default: "like", null: false
      t.timestamps
    end

    add_index :reactions, [ :user_id, :entry_id, :reaction_type ], unique: true, name: "idx_reactions_user_entry_type"
    add_index :reactions, [ :entry_id, :reaction_type ]
    add_foreign_key :reactions, :users
    add_foreign_key :reactions, :entries
  end
end
