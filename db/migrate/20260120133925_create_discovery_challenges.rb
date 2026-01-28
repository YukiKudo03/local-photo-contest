# frozen_string_literal: true

class CreateDiscoveryChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :discovery_challenges do |t|
      t.references :contest, null: false, foreign_key: true
      t.string :name, limit: 100, null: false
      t.text :description
      t.string :theme, limit: 100
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :discovery_challenges, [:contest_id, :status]
  end
end
