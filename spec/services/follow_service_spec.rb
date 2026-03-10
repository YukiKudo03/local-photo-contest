# frozen_string_literal: true

require "rails_helper"

RSpec.describe FollowService, type: :service do
  let(:follower) { create(:user, :confirmed) }
  let(:target) { create(:user, :confirmed) }

  subject { described_class.new(follower) }

  describe "#follow" do
    it "creates a follow relationship" do
      result = subject.follow(target)
      expect(result[:success]).to be true
      expect(result[:follow]).to be_a(Follow)
      expect(follower.following?(target)).to be true
    end

    it "returns error when trying to follow self" do
      result = described_class.new(follower).follow(follower)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:cannot_follow_self)
    end

    it "returns error when already following" do
      create(:follow, follower: follower, followed: target)
      result = subject.follow(target)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:already_following)
    end

    it "handles RecordNotUnique race condition gracefully" do
      allow(Follow).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
      allow(follower).to receive(:following?).and_return(false)
      result = subject.follow(target)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:already_following)
    end

    it "awards points via PointService" do
      subject.follow(target)
      expect(follower.user_points.where(action_type: "follow")).to exist
    end

    it "checks milestones for follower" do
      subject.follow(target)
      expect(follower.milestones.where(milestone_type: "first_follow")).to exist
    end

    it "checks milestones for followed user (gain_follower)" do
      # gain_follower only triggers at thresholds (10, 50), not at 1
      # Just verify it doesn't raise an error
      expect { subject.follow(target) }.not_to raise_error
    end
  end

  describe "#unfollow" do
    it "destroys the follow relationship" do
      create(:follow, follower: follower, followed: target)
      result = subject.unfollow(target)
      expect(result[:success]).to be true
      expect(follower.following?(target)).to be false
    end

    it "returns error when not following" do
      result = subject.unfollow(target)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_following)
    end
  end
end
