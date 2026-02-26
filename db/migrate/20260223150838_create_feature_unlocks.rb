# frozen_string_literal: true

class CreateFeatureUnlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_unlocks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :feature_key, null: false
      t.datetime :unlocked_at, null: false
      t.string :unlock_trigger  # どのアクションでアンロックされたか

      t.timestamps
    end

    add_index :feature_unlocks, [ :user_id, :feature_key ], unique: true
  end
end
