class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :name, null: false, limit: 100
      t.json :scopes, default: '["read"]'
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.datetime :expires_at
      t.timestamps
    end

    add_index :api_tokens, :token, unique: true
    add_index :api_tokens, [:user_id, :revoked_at]
  end
end
