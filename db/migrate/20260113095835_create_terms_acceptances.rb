class CreateTermsAcceptances < ActiveRecord::Migration[8.0]
  def change
    create_table :terms_acceptances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :terms_of_service, null: false, foreign_key: true
      t.datetime :accepted_at, null: false
      t.string :ip_address, null: false

      t.timestamps
    end

    add_index :terms_acceptances, [ :user_id, :terms_of_service_id ], unique: true
  end
end
