# frozen_string_literal: true

class AddAreaToContests < ActiveRecord::Migration[8.0]
  def change
    add_reference :contests, :area, foreign_key: true
    add_column :contests, :require_spot, :boolean, default: false
  end
end
