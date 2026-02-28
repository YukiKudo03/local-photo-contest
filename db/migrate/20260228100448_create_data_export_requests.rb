class CreateDataExportRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :data_export_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :requested_at
      t.datetime :completed_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
