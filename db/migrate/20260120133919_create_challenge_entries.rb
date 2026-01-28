# frozen_string_literal: true

class CreateChallengeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_entries do |t|
      t.references :discovery_challenge, null: false, foreign_key: true
      t.references :entry, null: false, foreign_key: true

      t.timestamps
    end

    add_index :challenge_entries, [:discovery_challenge_id, :entry_id], unique: true, name: "idx_challenge_entries_unique"
  end
end
