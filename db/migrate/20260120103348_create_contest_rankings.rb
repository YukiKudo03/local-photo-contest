class CreateContestRankings < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_rankings do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :entry, null: false, foreign_key: true
      t.integer :rank, null: false
      t.decimal :total_score, precision: 10, scale: 4, null: false
      t.decimal :judge_score, precision: 10, scale: 4
      t.decimal :vote_score, precision: 10, scale: 4
      t.integer :vote_count, default: 0
      t.datetime :calculated_at, null: false

      t.timestamps
    end

    add_index :contest_rankings, [ :contest_id, :rank ], unique: true
    add_index :contest_rankings, [ :contest_id, :entry_id ], unique: true
  end
end
