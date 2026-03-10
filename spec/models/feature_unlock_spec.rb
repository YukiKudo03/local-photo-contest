# frozen_string_literal: true

require "rails_helper"

RSpec.describe FeatureUnlock, type: :model do
  describe ".unlocked?" do
    let(:user) { create(:user, :confirmed) }

    it "returns true when feature is unlocked for user" do
      FeatureUnlock.create!(user: user, feature_key: "submit_entry", unlocked_at: Time.current)
      expect(FeatureUnlock.unlocked?(user, "submit_entry")).to be true
    end

    it "returns false when feature is not unlocked for user" do
      expect(FeatureUnlock.unlocked?(user, "submit_entry")).to be false
    end
  end
end
