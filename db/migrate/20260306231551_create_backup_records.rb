# frozen_string_literal: true

class CreateBackupRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :backup_records do |t|
      t.string :backup_type, null: false
      t.string :database_name, null: false
      t.integer :status, default: 0, null: false
      t.string :filename
      t.bigint :file_size
      t.string :checksum
      t.boolean :encrypted, default: false
      t.string :storage_location
      t.string :s3_bucket
      t.string :s3_key
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :backup_records, [ :backup_type, :created_at ]
    add_index :backup_records, :status
  end
end
