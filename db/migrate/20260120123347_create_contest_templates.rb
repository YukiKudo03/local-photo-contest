class CreateContestTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.references :source_contest, foreign_key: { to_table: :contests }
      t.string :name, null: false, limit: 100

      # Template settings (copied from Contest)
      t.string :theme, limit: 255
      t.text :description
      t.integer :judging_method, default: 0
      t.integer :judge_weight
      t.integer :prize_count
      t.boolean :moderation_enabled, default: true
      t.decimal :moderation_threshold, precision: 5, scale: 2
      t.boolean :require_spot, default: false
      t.references :area, foreign_key: true
      t.references :category, foreign_key: true

      t.timestamps

      t.index [ :user_id, :name ], unique: true
    end
  end
end
