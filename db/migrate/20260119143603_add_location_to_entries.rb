# frozen_string_literal: true

class AddLocationToEntries < ActiveRecord::Migration[8.0]
  def change
    add_reference :entries, :spot, foreign_key: true
    add_column :entries, :latitude, :decimal, precision: 10, scale: 7
    add_column :entries, :longitude, :decimal, precision: 10, scale: 7
    add_column :entries, :location_source, :integer, default: 0
  end
end
