# frozen_string_literal: true

class AddVotesCountToEntries < ActiveRecord::Migration[8.0]
  def up
    add_column :entries, :votes_count, :integer, default: 0, null: false

    # Backfill existing data using SQL
    execute <<-SQL.squish
      UPDATE entries
      SET votes_count = (
        SELECT COUNT(*)
        FROM votes
        WHERE votes.entry_id = entries.id
      )
    SQL
  end

  def down
    remove_column :entries, :votes_count
  end
end
