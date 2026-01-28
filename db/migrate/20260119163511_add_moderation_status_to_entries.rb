# frozen_string_literal: true

class AddModerationStatusToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :moderation_status, :integer, default: 0, null: false
    add_index :entries, :moderation_status
  end
end
