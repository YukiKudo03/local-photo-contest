class CreateJudgeComments < ActiveRecord::Migration[8.0]
  def change
    create_table :judge_comments do |t|
      t.references :contest_judge, null: false, foreign_key: true
      t.references :entry, null: false, foreign_key: true
      t.text :comment, null: false

      t.timestamps
    end

    add_index :judge_comments, [ :contest_judge_id, :entry_id ], unique: true
  end
end
