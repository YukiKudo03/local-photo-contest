class CreateTutorialSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :tutorial_steps do |t|
      t.string :tutorial_type, null: false
      t.string :step_id, null: false
      t.integer :position, null: false
      t.string :title, null: false
      t.text :description
      t.string :target_selector
      t.string :target_path
      t.string :tooltip_position, default: "bottom"
      t.json :options, default: {}

      t.timestamps
    end

    add_index :tutorial_steps, [ :tutorial_type, :step_id ], unique: true
    add_index :tutorial_steps, [ :tutorial_type, :position ]
  end
end
