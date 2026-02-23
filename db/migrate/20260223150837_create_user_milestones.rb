# frozen_string_literal: true

class CreateUserMilestones < ActiveRecord::Migration[8.0]
  def change
    create_table :user_milestones do |t|
      t.references :user, null: false, foreign_key: true
      t.string :milestone_type, null: false
      t.datetime :achieved_at, null: false
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :user_milestones, [:user_id, :milestone_type], unique: true
  end
end
