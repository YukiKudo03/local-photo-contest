class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :entry, null: false, foreign_key: true

      t.timestamps
    end

    # Prevent duplicate votes (one vote per user per entry)
    add_index :votes, [ :user_id, :entry_id ], unique: true
  end
end
