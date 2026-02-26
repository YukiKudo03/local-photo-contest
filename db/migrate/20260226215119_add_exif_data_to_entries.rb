class AddExifDataToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :exif_data, :json
  end
end
