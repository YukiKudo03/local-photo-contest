class CreateAreas < ActiveRecord::Migration[8.0]
  def change
    create_table :areas do |t|
      t.string :name, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :areas, :name, unique: true
    add_index :areas, :position

    # Add area_id to entries (single area per entry)
    add_reference :entries, :area, foreign_key: true
  end
end
