# frozen_string_literal: true

require "rails_helper"

RSpec.describe MilestoneService, "social milestones", type: :service do
  let(:user) { create(:user, :confirmed) }

  describe "#check_and_award(:follow)" do
    it "awards first_follow milestone" do
      expect {
        described_class.new(user).check_and_award(:follow)
      }.to change { user.milestones.where(milestone_type: "first_follow").count }.by(1)
    end

    it "does not duplicate first_follow" do
      described_class.new(user).check_and_award(:follow)
      expect {
        described_class.new(user).check_and_award(:follow)
      }.not_to change { user.milestones.count }
    end
  end

  describe "#check_and_award(:gain_follower)" do
    it "awards followers_10 milestone at threshold" do
      user.update_column(:followers_count, 10)
      expect {
        described_class.new(user).check_and_award(:gain_follower)
      }.to change { user.milestones.where(milestone_type: "followers_10").count }.by(1)
    end

    it "does not award followers_10 below threshold" do
      user.update_column(:followers_count, 9)
      expect {
        described_class.new(user).check_and_award(:gain_follower)
      }.not_to change { user.milestones.count }
    end
  end

  describe "#check_and_award(:receive_like)" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }

    it "awards likes_received_10 at threshold" do
      entry = create(:entry, user: user, contest: contest)
      10.times { create(:reaction, entry: entry) }

      expect {
        described_class.new(user).check_and_award(:receive_like)
      }.to change { user.milestones.where(milestone_type: "likes_received_10").count }.by(1)
    end
  end
end
