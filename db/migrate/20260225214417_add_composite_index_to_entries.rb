# frozen_string_literal: true

class AddCompositeIndexToEntries < ActiveRecord::Migration[8.0]
  def change
    # Composite index for gallery filtering (contest + moderation status)
    # This index optimizes queries that filter by both fields
    add_index :entries, [:contest_id, :moderation_status],
              name: "index_entries_on_contest_id_and_moderation_status",
              if_not_exists: true

    # Index for created_at to optimize time-based queries
    add_index :entries, :created_at,
              name: "index_entries_on_created_at",
              if_not_exists: true
  end
end
