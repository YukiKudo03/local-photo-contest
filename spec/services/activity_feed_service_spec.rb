# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityFeedService, type: :service do
  let(:user) { create(:user, :confirmed) }
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:followed_user) { create(:user, :confirmed) }
  let(:unfollowed_user) { create(:user, :confirmed) }

  subject { described_class.new(user) }

  before do
    create(:follow, follower: user, followed: followed_user)
  end

  describe "#feed" do
    it "returns entries from followed users" do
      entry = create(:entry, user: followed_user, contest: contest)
      feed = subject.feed
      expect(feed[:entries]).to include(entry)
    end

    it "does not return entries from unfollowed users" do
      entry = create(:entry, user: unfollowed_user, contest: contest)
      feed = subject.feed
      expect(feed[:entries]).not_to include(entry)
    end

    it "returns empty results when following no one" do
      lonely_user = create(:user, :confirmed)
      feed = described_class.new(lonely_user).feed
      expect(feed[:entries]).to be_empty
      expect(feed[:rankings]).to be_empty
    end

    it "returns rankings from followed users" do
      entry = create(:entry, user: followed_user, contest: contest)
      ranking = create(:contest_ranking, contest: contest, entry: entry, rank: 1)
      feed = subject.feed
      expect(feed[:rankings]).to include(ranking)
    end

    it "only returns top 3 rankings" do
      entry = create(:entry, user: followed_user, contest: contest)
      create(:contest_ranking, contest: contest, entry: entry, rank: 4)
      feed = subject.feed
      expect(feed[:rankings]).to be_empty
    end

    it "orders entries by most recent" do
      old_entry = create(:entry, user: followed_user, contest: contest, created_at: 2.days.ago)
      new_entry = create(:entry, user: followed_user, contest: contest, created_at: 1.hour.ago)
      feed = subject.feed
      expect(feed[:entries].first).to eq(new_entry)
    end
  end
end
