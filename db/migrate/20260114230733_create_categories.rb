class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :position

    # Add category_id to contests
    add_reference :contests, :category, foreign_key: true
  end
end
