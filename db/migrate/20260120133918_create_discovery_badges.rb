# frozen_string_literal: true

class CreateDiscoveryBadges < ActiveRecord::Migration[8.0]
  def change
    create_table :discovery_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contest, null: false, foreign_key: true
      t.integer :badge_type, null: false
      t.datetime :earned_at
      t.json :metadata

      t.timestamps
    end

    add_index :discovery_badges, [ :user_id, :contest_id, :badge_type ], unique: true, name: "idx_discovery_badges_unique"
  end
end
