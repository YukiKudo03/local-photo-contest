class AddMergedFieldsToSpots < ActiveRecord::Migration[8.0]
  def change
    add_column :spots, :merged_into_id, :integer
    add_column :spots, :merged_at, :datetime
    add_index :spots, :merged_into_id, where: "merged_into_id IS NOT NULL"
  end
end
