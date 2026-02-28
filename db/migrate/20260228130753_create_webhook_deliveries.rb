class CreateWebhookDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook, null: false, foreign_key: true
      t.string :event_type
      t.integer :status_code
      t.text :request_body
      t.text :response_body
      t.integer :retry_count, default: 0, null: false
      t.string :status, default: "pending", null: false
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
