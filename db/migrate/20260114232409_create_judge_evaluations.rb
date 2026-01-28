class CreateJudgeEvaluations < ActiveRecord::Migration[8.0]
  def change
    create_table :judge_evaluations do |t|
      t.references :contest_judge, null: false, foreign_key: true
      t.references :entry, null: false, foreign_key: true
      t.references :evaluation_criterion, null: false, foreign_key: { to_table: :evaluation_criteria }
      t.integer :score, null: false

      t.timestamps
    end

    add_index :judge_evaluations,
              [ :contest_judge_id, :entry_id, :evaluation_criterion_id ],
              unique: true,
              name: "idx_judge_evaluations_unique"
  end
end
