# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserProfileService, type: :service do
  let(:user) { create(:user, :confirmed) }
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  subject { described_class.new(user) }

  describe "#portfolio_entries" do
    it "returns user's entries" do
      entry = create(:entry, user: user, contest: contest)
      expect(subject.portfolio_entries).to include(entry)
    end

    it "limits results" do
      7.times { create(:entry, user: user, contest: contest) }
      expect(subject.portfolio_entries(limit: 6).count).to eq(6)
    end

    it "does not include other users' entries" do
      other_user = create(:user, :confirmed)
      create(:entry, user: other_user, contest: contest)
      expect(subject.portfolio_entries).to be_empty
    end
  end

  describe "#award_history" do
    it "returns rankings for user's entries" do
      entry = create(:entry, user: user, contest: contest)
      ranking = create(:contest_ranking, contest: contest, entry: entry)
      expect(subject.award_history).to include(ranking)
    end

    it "does not include other users' rankings" do
      other_user = create(:user, :confirmed)
      entry = create(:entry, user: other_user, contest: contest)
      create(:contest_ranking, contest: contest, entry: entry)
      expect(subject.award_history).to be_empty
    end
  end

  describe "#stats" do
    it "returns correct counts" do
      stats = subject.stats
      expect(stats[:entries_count]).to eq(0)
      expect(stats[:followers_count]).to eq(0)
      expect(stats[:following_count]).to eq(0)
      expect(stats[:total_likes_received]).to eq(0)
      expect(stats[:prizes_won]).to eq(0)
    end

    it "reflects actual data" do
      create(:entry, user: user, contest: contest)
      follower = create(:user, :confirmed)
      create(:follow, follower: follower, followed: user)

      stats = subject.stats
      expect(stats[:entries_count]).to eq(1)
      expect(stats[:followers_count]).to eq(1)
    end
  end
end
