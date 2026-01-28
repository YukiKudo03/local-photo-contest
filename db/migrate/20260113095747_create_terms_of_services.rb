class CreateTermsOfServices < ActiveRecord::Migration[8.0]
  def change
    create_table :terms_of_services do |t|
      t.string :version, null: false
      t.text :content, null: false
      t.datetime :published_at, null: false

      t.timestamps
    end
    add_index :terms_of_services, :version, unique: true
    add_index :terms_of_services, :published_at
  end
end
