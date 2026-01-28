# frozen_string_literal: true

class AddDiscoveryFieldsToSpots < ActiveRecord::Migration[8.0]
  def change
    add_column :spots, :discovery_status, :integer, default: 0, null: false
    add_column :spots, :discovered_by_id, :integer
    add_column :spots, :discovered_at, :datetime
    add_column :spots, :discovery_comment, :text
    add_column :spots, :certified_by_id, :integer
    add_column :spots, :certified_at, :datetime
    add_column :spots, :rejection_reason, :text
    add_column :spots, :votes_count, :integer, default: 0, null: false

    add_index :spots, :discovery_status
    add_index :spots, :discovered_by_id

    add_foreign_key :spots, :users, column: :discovered_by_id
    add_foreign_key :spots, :users, column: :certified_by_id
  end
end
