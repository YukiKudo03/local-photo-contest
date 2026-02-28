# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:webhook) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "#mark_delivered!" do
    it "updates status and delivered_at" do
      delivery = create(:webhook_delivery)
      delivery.mark_delivered!(200, '{"ok":true}')

      expect(delivery.status).to eq("delivered")
      expect(delivery.status_code).to eq(200)
      expect(delivery.delivered_at).to be_present
    end
  end

  describe "#mark_failed!" do
    it "updates status and increments retry_count" do
      delivery = create(:webhook_delivery)
      delivery.mark_failed!(500, "Error")

      expect(delivery.status).to eq("failed")
      expect(delivery.status_code).to eq(500)
      expect(delivery.retry_count).to eq(1)
    end
  end
end
