class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contest, foreign_key: true
      t.string :url, null: false
      t.string :secret
      t.json :event_types, default: "[]"
      t.boolean :active, default: true, null: false
      t.integer :failures_count, default: 0, null: false

      t.timestamps
    end
  end
end
