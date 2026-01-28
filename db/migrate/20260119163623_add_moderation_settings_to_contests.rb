# frozen_string_literal: true

class AddModerationSettingsToContests < ActiveRecord::Migration[8.0]
  def change
    add_column :contests, :moderation_enabled, :boolean, default: true, null: false
    add_column :contests, :moderation_threshold, :decimal, precision: 5, scale: 2, default: 60.0
  end
end
