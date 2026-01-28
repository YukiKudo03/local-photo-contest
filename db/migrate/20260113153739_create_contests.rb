class CreateContests < ActiveRecord::Migration[8.0]
  def change
    create_table :contests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, limit: 100
      t.text :description
      t.string :theme, limit: 255
      t.integer :status, default: 0, null: false
      t.datetime :entry_start_at
      t.datetime :entry_end_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :contests, :status
    add_index :contests, :deleted_at
    add_index :contests, [ :status, :deleted_at ]
  end
end
