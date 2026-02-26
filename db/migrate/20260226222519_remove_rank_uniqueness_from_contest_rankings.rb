# frozen_string_literal: true

class RemoveRankUniquenessFromContestRankings < ActiveRecord::Migration[8.0]
  def change
    # Remove unique constraint on rank to support standard competition ranking
    # where entries with identical scores receive the same rank
    remove_index :contest_rankings, [ :contest_id, :rank ]

    # Add non-unique index for performance
    add_index :contest_rankings, [ :contest_id, :rank ], name: "index_contest_rankings_on_contest_id_and_rank"
  end
end
