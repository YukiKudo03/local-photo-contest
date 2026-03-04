# frozen_string_literal: true

class AddImageAnalysisToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :quality_score, :float
    add_column :entries, :image_hash, :string, limit: 16
    add_column :entries, :image_analysis_completed_at, :datetime
    add_index :entries, :quality_score
    add_index :entries, :image_hash
  end
end
