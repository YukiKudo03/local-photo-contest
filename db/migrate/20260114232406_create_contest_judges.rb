class CreateContestJudges < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_judges do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :invited_at

      t.timestamps
    end

    add_index :contest_judges, [ :contest_id, :user_id ], unique: true
  end
end
