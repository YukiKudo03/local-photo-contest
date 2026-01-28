# frozen_string_literal: true

class CreateModerationResults < ActiveRecord::Migration[8.0]
  def change
    create_table :moderation_results do |t|
      t.references :entry, null: false, foreign_key: true, index: { unique: true }
      t.string :provider, null: false
      t.integer :status, null: false, default: 0
      t.json :labels
      t.decimal :max_confidence, precision: 5, scale: 2
      t.json :raw_response
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.text :review_note

      t.timestamps
    end

    add_index :moderation_results, :status
  end
end
