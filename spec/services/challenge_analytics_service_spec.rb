# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChallengeAnalyticsService do
  let(:contest) { create(:contest, :published) }
  let(:challenge) do
    create(:discovery_challenge, :active, contest: contest,
           starts_at: 7.days.ago, ends_at: 7.days.from_now)
  end

  describe "#summary" do
    subject(:service) { described_class.new(challenge) }

    context "with no entries" do
      it "returns zero counts" do
        summary = service.summary

        expect(summary[:total_entries]).to eq(0)
        expect(summary[:total_participants]).to eq(0)
        expect(summary[:discovered_spots]).to eq(0)
        expect(summary[:certified_spots]).to eq(0)
      end
    end

    context "with entries and spots" do
      let(:user1) { create(:user, :confirmed) }
      let(:user2) { create(:user, :confirmed) }
      let(:discovered_spot) { create(:spot, :discovered, contest: contest) }
      let(:certified_spot) { create(:spot, :certified, contest: contest) }

      before do
        # User1 submits 2 entries
        entry1 = create(:entry, contest: contest, user: user1, spot: discovered_spot)
        entry2 = create(:entry, contest: contest, user: user1, spot: certified_spot)

        # User2 submits 1 entry
        entry3 = create(:entry, contest: contest, user: user2, spot: certified_spot)

        # Link entries to challenge
        create(:challenge_entry, discovery_challenge: challenge, entry: entry1)
        create(:challenge_entry, discovery_challenge: challenge, entry: entry2)
        create(:challenge_entry, discovery_challenge: challenge, entry: entry3)
      end

      it "returns correct total entries count" do
        summary = service.summary
        expect(summary[:total_entries]).to eq(3)
      end

      it "returns correct total participants count" do
        summary = service.summary
        expect(summary[:total_participants]).to eq(2)
      end

      it "returns correct discovered spots count" do
        summary = service.summary
        expect(summary[:discovered_spots]).to eq(1)
      end

      it "returns correct certified spots count" do
        summary = service.summary
        expect(summary[:certified_spots]).to eq(1)
      end
    end
  end

  describe "#participant_ranking" do
    subject(:service) { described_class.new(challenge) }

    let(:user1) { create(:user, :confirmed, name: "Top User") }
    let(:user2) { create(:user, :confirmed, name: "Second User") }
    let(:user3) { create(:user, :confirmed, name: "Third User") }

    before do
      # User1 has 3 entries
      3.times do
        entry = create(:entry, contest: contest, user: user1)
        create(:challenge_entry, discovery_challenge: challenge, entry: entry)
      end

      # User2 has 2 entries
      2.times do
        entry = create(:entry, contest: contest, user: user2)
        create(:challenge_entry, discovery_challenge: challenge, entry: entry)
      end

      # User3 has 1 entry
      entry = create(:entry, contest: contest, user: user3)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry)
    end

    it "returns participants ordered by entry count" do
      ranking = service.participant_ranking

      expect(ranking.first[:user].name).to eq("Top User")
      expect(ranking.second[:user].name).to eq("Second User")
      expect(ranking.third[:user].name).to eq("Third User")
    end

    it "includes entry count for each participant" do
      ranking = service.participant_ranking

      expect(ranking.first[:entries_count]).to eq(3)
      expect(ranking.second[:entries_count]).to eq(2)
      expect(ranking.third[:entries_count]).to eq(1)
    end

    it "respects the limit parameter" do
      ranking = service.participant_ranking(limit: 2)
      expect(ranking.size).to eq(2)
    end
  end

  describe "#daily_activity" do
    subject(:service) { described_class.new(challenge) }

    let(:user) { create(:user, :confirmed) }

    before do
      # Create entries on different days (using created_at directly)
      2.times do
        entry = create(:entry, contest: contest, user: user, created_at: 5.days.ago)
        create(:challenge_entry, discovery_challenge: challenge, entry: entry, created_at: 5.days.ago)
      end

      entry = create(:entry, contest: contest, user: user, created_at: 3.days.ago)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry, created_at: 3.days.ago)

      entry = create(:entry, contest: contest, user: user, created_at: 1.day.ago)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry, created_at: 1.day.ago)
    end

    it "returns daily entry counts" do
      activity = service.daily_activity

      expect(activity).to be_an(Array)
      expect(activity.any? { |day| day[:count] > 0 }).to be true
    end

    it "includes date and count for each day" do
      activity = service.daily_activity.first

      expect(activity).to have_key(:date)
      expect(activity).to have_key(:count)
    end
  end

  describe "#spot_distribution" do
    subject(:service) { described_class.new(challenge) }

    let(:user) { create(:user, :confirmed) }
    let(:spot1) { create(:spot, :certified, contest: contest, category: :restaurant) }
    let(:spot2) { create(:spot, :certified, contest: contest, category: :landmark) }
    let(:spot3) { create(:spot, :certified, contest: contest, category: :restaurant) }

    before do
      # 2 entries for restaurant spots
      entry1 = create(:entry, contest: contest, user: user, spot: spot1)
      entry2 = create(:entry, contest: contest, user: user, spot: spot3)
      # 1 entry for landmark spot
      entry3 = create(:entry, contest: contest, user: user, spot: spot2)

      create(:challenge_entry, discovery_challenge: challenge, entry: entry1)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry2)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry3)
    end

    it "returns spot counts by category" do
      distribution = service.spot_distribution

      expect(distribution[:restaurant]).to eq(2)
      expect(distribution[:landmark]).to eq(1)
    end
  end

  describe ".compare_challenges" do
    let(:challenge1) do
      create(:discovery_challenge, :finished, contest: contest,
             name: "Challenge 1", starts_at: 14.days.ago, ends_at: 7.days.ago)
    end
    let(:challenge2) do
      create(:discovery_challenge, :active, contest: contest,
             name: "Challenge 2", starts_at: 7.days.ago, ends_at: 7.days.from_now)
    end

    let(:user) { create(:user, :confirmed) }

    before do
      # Challenge 1: 5 entries
      5.times do
        entry = create(:entry, contest: contest, user: user)
        create(:challenge_entry, discovery_challenge: challenge1, entry: entry)
      end

      # Challenge 2: 3 entries
      3.times do
        entry = create(:entry, contest: contest, user: user)
        create(:challenge_entry, discovery_challenge: challenge2, entry: entry)
      end
    end

    it "compares multiple challenges" do
      comparison = described_class.compare_challenges([ challenge1, challenge2 ])

      expect(comparison.length).to eq(2)
      expect(comparison.first[:name]).to eq("Challenge 1")
      expect(comparison.first[:total_entries]).to eq(5)
      expect(comparison.second[:name]).to eq("Challenge 2")
      expect(comparison.second[:total_entries]).to eq(3)
    end
  end
end
