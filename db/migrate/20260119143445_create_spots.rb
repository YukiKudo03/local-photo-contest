# frozen_string_literal: true

class CreateSpots < ActiveRecord::Migration[8.0]
  def change
    create_table :spots do |t|
      t.references :contest, null: false, foreign_key: true
      t.string :name, limit: 100, null: false
      t.integer :category, default: 0, null: false
      t.string :address, limit: 200
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.text :description
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :spots, [ :contest_id, :position ]
    add_index :spots, [ :contest_id, :name ], unique: true
  end
end
