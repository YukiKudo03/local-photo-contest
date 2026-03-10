# frozen_string_literal: true

require "rails_helper"

RSpec.describe Follow, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:follower).class_name("User") }
    it { is_expected.to belong_to(:followed).class_name("User") }
  end

  describe "validations" do
    subject { build(:follow) }

    it { is_expected.to validate_uniqueness_of(:follower_id).scoped_to(:followed_id) }

    it "prevents following self" do
      user = create(:user, :confirmed)
      follow = build(:follow, follower: user, followed: user)
      expect(follow).not_to be_valid
      expect(follow.errors[:base]).to include(I18n.t("errors.messages.cannot_follow_self"))
    end
  end

  describe "scopes" do
    let!(:user_a) { create(:user, :confirmed) }
    let!(:user_b) { create(:user, :confirmed) }
    let!(:user_c) { create(:user, :confirmed) }
    let!(:follow_ab) { create(:follow, follower: user_a, followed: user_b) }
    let!(:follow_ac) { create(:follow, follower: user_a, followed: user_c) }
    let!(:follow_ba) { create(:follow, follower: user_b, followed: user_a) }

    it "by_follower returns follows where user is follower" do
      expect(described_class.by_follower(user_a)).to contain_exactly(follow_ab, follow_ac)
    end

    it "by_followed returns follows where user is followed" do
      expect(described_class.by_followed(user_a)).to contain_exactly(follow_ba)
    end

    it "recent orders by created_at desc" do
      expect(described_class.recent.first).to eq(follow_ba)
    end
  end

  describe "counter cache" do
    let(:follower) { create(:user, :confirmed) }
    let(:followed) { create(:user, :confirmed) }

    it "increments followers_count on followed user when created" do
      expect {
        create(:follow, follower: follower, followed: followed)
      }.to change { followed.reload.followers_count }.by(1)
    end

    it "decrements followers_count on followed user when destroyed" do
      follow = create(:follow, follower: follower, followed: followed)
      expect {
        follow.destroy!
      }.to change { followed.reload.followers_count }.by(-1)
    end

    it "updates following_count on follower when created" do
      expect {
        create(:follow, follower: follower, followed: followed)
      }.to change { follower.reload.following_count }.by(1)
    end

    it "updates following_count on follower when destroyed" do
      follow = create(:follow, follower: follower, followed: followed)
      expect {
        follow.destroy!
      }.to change { follower.reload.following_count }.by(-1)
    end
  end

  describe "notification callback error handling" do
    it "does not raise when follow notification job fails to enqueue" do
      allow(FollowNotificationJob).to receive(:perform_later).and_raise(StandardError, "enqueue error")
      user_a = create(:user, :confirmed)
      user_b = create(:user, :confirmed)
      expect { create(:follow, follower: user_a, followed: user_b) }.not_to raise_error
    end
  end

  describe "database constraints" do
    it "enforces unique index on [follower_id, followed_id]" do
      user_a = create(:user, :confirmed)
      user_b = create(:user, :confirmed)
      create(:follow, follower: user_a, followed: user_b)
      duplicate = build(:follow, follower: user_a, followed: user_b)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:follower_id]).to be_present
    end
  end
end
