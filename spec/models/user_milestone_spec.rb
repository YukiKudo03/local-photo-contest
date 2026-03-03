# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMilestone, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "TYPES" do
    it "includes original 6 types" do
      %w[first_vote first_submission first_contest_published
         first_contest_completed all_entries_judged tutorial_completed].each do |t|
        expect(UserMilestone::TYPES.values).to include(t)
      end
    end

    it "includes consecutive participation milestones" do
      %w[consecutive_3_contests consecutive_5_contests consecutive_10_contests].each do |t|
        expect(UserMilestone::TYPES.values).to include(t)
      end
    end

    it "includes prize count milestones" do
      %w[prize_bronze prize_silver prize_gold].each do |t|
        expect(UserMilestone::TYPES.values).to include(t)
      end
    end

    it "includes comment count milestones" do
      %w[comments_10 comments_50].each do |t|
        expect(UserMilestone::TYPES.values).to include(t)
      end
    end

    it "includes vote participation milestones" do
      %w[votes_10 votes_50].each do |t|
        expect(UserMilestone::TYPES.values).to include(t)
      end
    end
  end

  describe "BADGES" do
    it "has badge info for every milestone type" do
      UserMilestone::TYPES.values.each do |type|
        badge = UserMilestone::BADGES[type]
        expect(badge).to be_present, "Missing badge for #{type}"
        expect(badge).to have_key(:name)
        expect(badge).to have_key(:icon)
        expect(badge).to have_key(:color)
      end
    end
  end

  describe "validations" do
    let(:user) { create(:user, :confirmed) }

    it "validates milestone_type inclusion with new types" do
      milestone = UserMilestone.new(user: user, milestone_type: "consecutive_3_contests", achieved_at: Time.current)
      expect(milestone).to be_valid
    end

    it "rejects invalid milestone type" do
      milestone = UserMilestone.new(user: user, milestone_type: "invalid_type", achieved_at: Time.current)
      expect(milestone).not_to be_valid
    end
  end

  describe ".achieve!" do
    let(:user) { create(:user, :confirmed) }

    it "creates a new milestone for consecutive_3_contests" do
      expect {
        UserMilestone.achieve!(user, "consecutive_3_contests", { streak: 3 })
      }.to change(UserMilestone, :count).by(1)
    end

    it "stores metadata in the milestone" do
      UserMilestone.achieve!(user, "prize_bronze", { prize_count: 1 })
      milestone = user.milestones.find_by(milestone_type: "prize_bronze")
      expect(milestone.metadata).to include("prize_count" => 1)
    end

    it "does not duplicate if already achieved" do
      UserMilestone.achieve!(user, "votes_10")
      expect {
        UserMilestone.achieve!(user, "votes_10")
      }.not_to change(UserMilestone, :count)
    end
  end
end
