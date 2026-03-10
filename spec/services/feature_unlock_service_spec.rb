# frozen_string_literal: true

require "rails_helper"

RSpec.describe FeatureUnlockService do
  let(:user) { create(:user, :confirmed) }
  let(:service) { described_class.new(user) }

  describe "#unlock_for_trigger" do
    it "unlocks features matching the trigger" do
      service.unlock_for_trigger(:first_vote)

      expect(user.feature_unlocks.pluck(:feature_key)).to include("submit_entry", "comment")
    end

    it "broadcasts unlocks when features are unlocked" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).with(
        "user_#{user.id}_notifications",
        target: "feature-unlocks",
        partial: "tutorials/feature_unlock_notification",
        locals: { features: anything }
      )

      service.unlock_for_trigger(:first_vote)
    end

    it "does not broadcast when no features match the trigger" do
      expect(Turbo::StreamsChannel).not_to receive(:broadcast_append_to)
      service.unlock_for_trigger(:nonexistent_trigger)
    end
  end

  describe "#unlock_feature" do
    it "unlocks a specific feature" do
      service.unlock_feature("submit_entry", "manual")
      expect(user.feature_unlocks.exists?(feature_key: "submit_entry")).to be true
    end
  end

  describe "#unlocked?" do
    it "returns false when feature is not unlocked" do
      expect(service.unlocked?("submit_entry")).to be false
    end

    it "returns true when feature is unlocked" do
      FeatureUnlock.unlock!(user, "submit_entry", "first_vote")
      expect(service.unlocked?("submit_entry")).to be true
    end
  end

  describe "#all_unlocked_features" do
    it "returns all unlocked feature keys" do
      FeatureUnlock.unlock!(user, "submit_entry", "first_vote")
      FeatureUnlock.unlock!(user, "comment", "first_vote")
      expect(service.all_unlocked_features).to contain_exactly("submit_entry", "comment")
    end
  end

  describe "broadcast_unlocks rescue" do
    it "logs warning when broadcast fails and does not raise" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_raise(StandardError, "broadcast error")
      expect(Rails.logger).to receive(:warn).with(/Failed to broadcast unlocks/)

      expect { service.unlock_for_trigger(:first_vote) }.not_to raise_error
    end
  end
end
