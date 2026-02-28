# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe WebhookDeliveryJob, type: :job do
  let(:webhook) { create(:webhook, secret: "test-secret") }
  let(:delivery) { create(:webhook_delivery, webhook: webhook) }

  before { WebMock.disable_net_connect! }
  after { WebMock.allow_net_connect! }

  describe "#perform" do
    it "sends HTTP POST with signature header" do
      stub = stub_request(:post, webhook.url)
        .with(headers: { "X-Webhook-Signature" => /\A[a-f0-9]+\z/ })
        .to_return(status: 200, body: '{"ok":true}')

      described_class.new.perform(delivery.id)

      expect(stub).to have_been_requested
      expect(delivery.reload.status).to eq("delivered")
    end

    it "records failure on HTTP error" do
      stub_request(:post, webhook.url).to_return(status: 500, body: "Error")

      described_class.new.perform(delivery.id)

      expect(delivery.reload.status).to eq("failed")
      expect(delivery.status_code).to eq(500)
    end

    it "increments webhook failures_count on error" do
      stub_request(:post, webhook.url).to_return(status: 500, body: "Error")

      expect {
        described_class.new.perform(delivery.id)
      }.to change { webhook.reload.failures_count }.by(1)
    end

    it "resets failures_count on success" do
      webhook.update!(failures_count: 5)
      stub_request(:post, webhook.url).to_return(status: 200, body: "OK")

      described_class.new.perform(delivery.id)

      expect(webhook.reload.failures_count).to eq(0)
    end

    it "disables webhook after 10 failures" do
      webhook.update!(failures_count: 9)
      stub_request(:post, webhook.url).to_return(status: 500, body: "Error")

      described_class.new.perform(delivery.id)

      expect(webhook.reload.active).to be false
    end
  end
end
