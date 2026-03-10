# frozen_string_literal: true

require "rails_helper"

RSpec.describe Webhook, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:contest).optional }
    it { is_expected.to have_many(:webhook_deliveries).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:url) }

    it "requires HTTPS URL" do
      webhook = build(:webhook, url: "http://example.com/hook")
      expect(webhook).not_to be_valid
      expect(webhook.errors[:url]).to be_present
    end

    it "accepts HTTPS URL" do
      webhook = build(:webhook, url: "https://example.com/hook")
      expect(webhook).to be_valid
    end

    it "validates event_types are valid" do
      webhook = build(:webhook, event_types: '["invalid.event"]')
      expect(webhook).not_to be_valid
    end
  end

  describe ".for_event" do
    let!(:matching) { create(:webhook, event_types: '["entry.created"]') }
    let!(:non_matching) { create(:webhook, event_types: '["vote.created"]') }
    let!(:inactive) { create(:webhook, :inactive, event_types: '["entry.created"]') }

    it "returns active webhooks matching the event" do
      result = Webhook.for_event("entry.created")
      expect(result).to include(matching)
      expect(result).not_to include(non_matching, inactive)
    end
  end

  describe "#subscribes_to?" do
    let(:webhook) { build(:webhook, event_types: '["entry.created","vote.created"]') }

    it "returns true for subscribed event" do
      expect(webhook.subscribes_to?("entry.created")).to be true
    end

    it "returns false for non-subscribed event" do
      expect(webhook.subscribes_to?("contest.status_changed")).to be false
    end
  end

  describe "#disable_if_failing!" do
    it "disables webhook after 10 failures" do
      webhook = create(:webhook, failures_count: 10)
      webhook.disable_if_failing!
      expect(webhook.reload.active).to be false
    end

    it "does not disable with fewer failures" do
      webhook = create(:webhook, failures_count: 5)
      webhook.disable_if_failing!
      expect(webhook.reload.active).to be true
    end
  end

  describe "#parsed_event_types" do
    it "returns array when event_types is an Array" do
      webhook = build(:webhook, event_types: ["entry.created"])
      expect(webhook.parsed_event_types).to eq(["entry.created"])
    end

    it "returns empty array on JSON parse error" do
      webhook = build(:webhook)
      webhook.event_types = "not valid json{"
      expect(webhook.parsed_event_types).to eq([])
    end

    it "returns empty array when event_types is nil" do
      webhook = build(:webhook, event_types: nil)
      expect(webhook.parsed_event_types).to eq([])
    end
  end

  describe "url validation" do
    it "adds invalid error for malformed URI" do
      webhook = build(:webhook, url: "ht tp://bad url")
      expect(webhook).not_to be_valid
      expect(webhook.errors[:url]).to be_present
    end
  end

  describe "#compute_signature" do
    let(:webhook) { build(:webhook, secret: "test-secret") }

    it "returns HMAC SHA256 signature" do
      payload = '{"event":"test"}'
      signature = webhook.compute_signature(payload)
      expected = OpenSSL::HMAC.hexdigest("SHA256", "test-secret", payload)
      expect(signature).to eq(expected)
    end
  end
end
