# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookDispatcher, type: :service do
  describe ".dispatch" do
    let!(:matching_webhook) { create(:webhook, event_types: '["entry.created"]') }
    let!(:non_matching_webhook) { create(:webhook, event_types: '["vote.created"]') }

    it "enqueues jobs for matching webhooks" do
      payload = { entry_id: 1 }

      expect {
        WebhookDispatcher.dispatch("entry.created", payload)
      }.to have_enqueued_job(WebhookDeliveryJob)
    end

    it "creates delivery records for matching webhooks" do
      payload = { entry_id: 1 }

      expect {
        WebhookDispatcher.dispatch("entry.created", payload)
      }.to change(WebhookDelivery, :count).by(1)
    end

    it "does not enqueue for non-matching webhooks" do
      payload = { contest_id: 1 }

      expect {
        WebhookDispatcher.dispatch("contest.status_changed", payload)
      }.not_to have_enqueued_job(WebhookDeliveryJob)
    end
  end
end
