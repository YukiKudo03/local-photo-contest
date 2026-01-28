class CreateEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contest, null: false, foreign_key: true
      t.string :title, limit: 100
      t.text :description
      t.string :location, limit: 255
      t.date :taken_at

      t.timestamps
    end

    add_index :entries, [ :user_id, :contest_id ]
  end
end
