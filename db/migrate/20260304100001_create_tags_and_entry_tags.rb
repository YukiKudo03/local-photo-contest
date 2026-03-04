# frozen_string_literal: true

class CreateTagsAndEntryTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false, limit: 100
      t.string :name_ja, limit: 100
      t.string :category, limit: 50
      t.integer :entries_count, default: 0, null: false
      t.timestamps
    end
    add_index :tags, :name, unique: true
    add_index :tags, :category

    create_table :entry_tags do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.float :confidence
      t.timestamps
    end
    add_index :entry_tags, [ :entry_id, :tag_id ], unique: true
  end
end
