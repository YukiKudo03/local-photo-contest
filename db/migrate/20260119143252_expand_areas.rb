# frozen_string_literal: true

class ExpandAreas < ActiveRecord::Migration[8.0]
  def change
    add_reference :areas, :user, null: false, foreign_key: true
    add_column :areas, :prefecture, :string, limit: 20
    add_column :areas, :city, :string, limit: 50
    add_column :areas, :address, :string, limit: 200
    add_column :areas, :latitude, :decimal, precision: 10, scale: 7
    add_column :areas, :longitude, :decimal, precision: 10, scale: 7
    add_column :areas, :boundary_geojson, :text
    add_column :areas, :description, :text

    # Remove global uniqueness index on name, will add scoped uniqueness in model
    remove_index :areas, :name
    add_index :areas, [ :user_id, :name ], unique: true
  end
end
