class CreateTutorialProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :tutorial_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tutorial_type, null: false
      t.string :current_step_id
      t.boolean :completed, default: false
      t.boolean :skipped, default: false
      t.datetime :started_at
      t.datetime :completed_at
      t.json :step_data, default: {}

      t.timestamps
    end

    add_index :tutorial_progresses, [:user_id, :tutorial_type], unique: true
    add_index :tutorial_progresses, :completed
  end
end
