# frozen_string_literal: true

class CreateSpotVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :spot_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :spot, null: false, foreign_key: true

      t.timestamps
    end

    add_index :spot_votes, [:user_id, :spot_id], unique: true
  end
end
