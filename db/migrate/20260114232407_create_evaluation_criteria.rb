class CreateEvaluationCriteria < ActiveRecord::Migration[8.0]
  def change
    create_table :evaluation_criteria do |t|
      t.references :contest, null: false, foreign_key: true
      t.string :name, null: false, limit: 50
      t.text :description
      t.integer :position, default: 0
      t.integer :max_score, null: false, default: 10

      t.timestamps
    end

    add_index :evaluation_criteria, [ :contest_id, :position ]
    add_index :evaluation_criteria, [ :contest_id, :name ], unique: true
  end
end
