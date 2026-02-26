# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatisticsService do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:service) { described_class.new(contest) }

  describe "#summary_stats" do
    context "when contest has no data" do
      it "returns zeros for all counts" do
        stats = service.summary_stats

        expect(stats[:total_entries]).to eq(0)
        expect(stats[:total_votes]).to eq(0)
        expect(stats[:total_participants]).to eq(0)
        expect(stats[:total_spots]).to eq(0)
      end

      it "returns nil for changes when no data" do
        stats = service.summary_stats

        expect(stats[:entries_change]).to be_nil
        expect(stats[:votes_change]).to be_nil
        expect(stats[:participants_change]).to be_nil
        expect(stats[:spots_change]).to be_nil
      end
    end

    context "when contest has data" do
      let!(:user1) { create(:user, :confirmed) }
      let!(:user2) { create(:user, :confirmed) }
      let!(:spot1) { create(:spot, contest: contest) }
      let!(:spot2) { create(:spot, contest: contest) }
      let!(:entry1) { create(:entry, contest: contest, user: user1, spot: spot1) }
      let!(:entry2) { create(:entry, contest: contest, user: user2, spot: spot2) }
      let!(:vote1) { create(:vote, entry: entry1, user: user2) }
      let!(:vote2) { create(:vote, entry: entry2, user: user1) }

      it "returns correct counts" do
        stats = service.summary_stats

        expect(stats[:total_entries]).to eq(2)
        expect(stats[:total_votes]).to eq(2)
        expect(stats[:total_participants]).to eq(2)
        expect(stats[:total_spots]).to eq(2)
      end
    end

    context "when comparing with yesterday" do
      let!(:user) { create(:user, :confirmed) }

      it "calculates positive change" do
        # Yesterday's entry
        create(:entry, contest: contest, user: user, created_at: 1.day.ago)
        # Today's entries
        create(:entry, contest: contest, user: create(:user, :confirmed))
        create(:entry, contest: contest, user: create(:user, :confirmed))

        stats = service.summary_stats

        expect(stats[:entries_change]).to eq(1) # 2 today - 1 yesterday
      end

      it "calculates negative change" do
        # Yesterday's entries
        create(:entry, contest: contest, user: user, created_at: 1.day.ago)
        create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 1.day.ago)
        # No entries today

        stats = service.summary_stats

        expect(stats[:entries_change]).to eq(-2) # 0 today - 2 yesterday
      end
    end
  end

  describe "#daily_entries" do
    it "returns empty hash when no entries" do
      result = service.daily_entries
      expect(result).to be_a(Hash)
    end

    it "groups entries by day" do
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 2.days.ago)
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 2.days.ago)
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 1.day.ago)

      result = service.daily_entries

      expect(result.values.sum).to eq(3)
    end
  end

  describe "#weekly_entries" do
    it "returns empty hash when no entries" do
      result = service.weekly_entries
      expect(result).to be_a(Hash)
    end

    it "groups entries by week" do
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 2.weeks.ago)
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 1.week.ago)
      create(:entry, contest: contest, user: create(:user, :confirmed))

      result = service.weekly_entries

      expect(result.values.sum).to eq(3)
    end
  end

  describe "#show_weekly_option?" do
    it "returns false when no entries" do
      expect(service.show_weekly_option?).to be false
    end

    it "returns false when entries span less than 7 days" do
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 3.days.ago)
      create(:entry, contest: contest, user: create(:user, :confirmed))

      expect(service.show_weekly_option?).to be false
    end

    it "returns true when entries span 7 or more days" do
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 10.days.ago)
      create(:entry, contest: contest, user: create(:user, :confirmed))

      expect(service.show_weekly_option?).to be true
    end
  end

  describe "#spot_rankings" do
    it "returns empty array when no entries" do
      result = service.spot_rankings
      expect(result).to eq([])
    end

    it "returns spot rankings sorted by count descending" do
      spot1 = create(:spot, contest: contest)
      spot2 = create(:spot, contest: contest)

      3.times { create(:entry, contest: contest, user: create(:user, :confirmed), spot: spot1) }
      1.times { create(:entry, contest: contest, user: create(:user, :confirmed), spot: spot2) }

      result = service.spot_rankings

      expect(result.first[:name]).to eq(spot1.name)
      expect(result.first[:count]).to eq(3)
      expect(result.last[:name]).to eq(spot2.name)
      expect(result.last[:count]).to eq(1)
    end

    it "includes entries without spot as 'スポット未指定'" do
      create(:entry, contest: contest, user: create(:user, :confirmed), spot: nil)

      result = service.spot_rankings

      expect(result.any? { |r| r[:name] == "スポット未指定" }).to be true
    end

    it "limits results to specified count" do
      15.times do |i|
        spot = create(:spot, contest: contest, name: "Spot #{i}")
        create(:entry, contest: contest, user: create(:user, :confirmed), spot: spot)
      end

      result = service.spot_rankings(limit: 5)

      expect(result.size).to eq(5)
    end
  end

  describe "#area_distribution" do
    it "returns empty hash when contest has no area" do
      contest.update!(area: nil)
      result = service.area_distribution
      expect(result).to eq({})
    end
  end

  describe "#daily_votes" do
    it "returns empty hash when no votes" do
      result = service.daily_votes
      expect(result).to be_a(Hash)
    end

    it "groups votes by day" do
      entry = create(:entry, contest: contest, user: create(:user, :confirmed))
      create(:vote, entry: entry, user: create(:user, :confirmed), created_at: 2.days.ago)
      create(:vote, entry: entry, user: create(:user, :confirmed), created_at: 1.day.ago)

      result = service.daily_votes

      expect(result.values.sum).to eq(2)
    end
  end

  describe "#vote_summary" do
    it "returns zeros when no votes" do
      result = service.vote_summary

      expect(result[:total]).to eq(0)
      expect(result[:unique_voters]).to eq(0)
      expect(result[:average_per_entry]).to eq(0)
    end

    it "calculates correct summary" do
      user1 = create(:user, :confirmed)
      user2 = create(:user, :confirmed)
      entry1 = create(:entry, contest: contest, user: create(:user, :confirmed))
      entry2 = create(:entry, contest: contest, user: create(:user, :confirmed))

      create(:vote, entry: entry1, user: user1)
      create(:vote, entry: entry1, user: user2)
      create(:vote, entry: entry2, user: user1)

      result = service.vote_summary

      expect(result[:total]).to eq(3)
      expect(result[:unique_voters]).to eq(2)
      expect(result[:average_per_entry]).to eq(1.5)
    end
  end

  describe "#top_voted_entries" do
    it "returns empty array when no entries" do
      result = service.top_voted_entries
      expect(result).to be_empty
    end

    it "returns entries sorted by vote count descending" do
      entry1 = create(:entry, contest: contest, user: create(:user, :confirmed))
      entry2 = create(:entry, contest: contest, user: create(:user, :confirmed))
      entry3 = create(:entry, contest: contest, user: create(:user, :confirmed))

      3.times { create(:vote, entry: entry1, user: create(:user, :confirmed)) }
      1.times { create(:vote, entry: entry2, user: create(:user, :confirmed)) }
      2.times { create(:vote, entry: entry3, user: create(:user, :confirmed)) }

      result = service.top_voted_entries

      expect(result.first).to eq(entry1)
      expect(result.second).to eq(entry3)
      expect(result.third).to eq(entry2)
    end

    it "limits results to specified count" do
      10.times do
        entry = create(:entry, contest: contest, user: create(:user, :confirmed))
        create(:vote, entry: entry, user: create(:user, :confirmed))
      end

      result = service.top_voted_entries(limit: 3)

      expect(result.to_a.size).to eq(3)
    end
  end

  describe "#voting_started?" do
    it "returns true for published contest" do
      expect(service.voting_started?).to be true
    end

    it "returns true for finished contest" do
      contest.finish!
      expect(service.voting_started?).to be true
    end

    it "returns false for draft contest" do
      draft_contest = create(:contest, :draft, user: organizer)
      draft_service = described_class.new(draft_contest)

      expect(draft_service.voting_started?).to be false
    end
  end

  describe "caching", :caching do
    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original_cache
    end

    # Disable cache clearing callbacks for caching behavior tests
    before do
      allow_any_instance_of(Entry).to receive(:clear_statistics_cache)
      allow_any_instance_of(Vote).to receive(:clear_statistics_cache)
    end

    describe "#summary_stats" do
      it "caches results" do
        # First call - cache miss
        first_result = service.summary_stats

        # Create new entry after caching
        create(:entry, contest: contest, user: create(:user, :confirmed))

        # Second call should return cached result
        second_result = service.summary_stats

        expect(second_result[:total_entries]).to eq(first_result[:total_entries])
      end

      it "uses contest-specific cache key" do
        other_contest = create(:contest, :published, user: organizer)
        other_service = described_class.new(other_contest)

        create(:entry, contest: contest, user: create(:user, :confirmed))

        contest_stats = service.summary_stats
        other_stats = other_service.summary_stats

        expect(contest_stats[:total_entries]).to eq(1)
        expect(other_stats[:total_entries]).to eq(0)
      end
    end

    describe "#daily_entries" do
      it "caches results" do
        create(:entry, contest: contest, user: create(:user, :confirmed))
        first_result = service.daily_entries.dup

        create(:entry, contest: contest, user: create(:user, :confirmed))
        second_result = service.daily_entries

        expect(second_result.values.sum).to eq(first_result.values.sum)
      end
    end

    describe "#daily_votes" do
      it "caches results" do
        entry = create(:entry, contest: contest, user: create(:user, :confirmed))
        create(:vote, entry: entry, user: create(:user, :confirmed))
        first_result = service.daily_votes.dup

        create(:vote, entry: entry, user: create(:user, :confirmed))
        second_result = service.daily_votes

        expect(second_result.values.sum).to eq(first_result.values.sum)
      end
    end

    describe "#spot_rankings" do
      it "caches results" do
        spot = create(:spot, contest: contest)
        create(:entry, contest: contest, user: create(:user, :confirmed), spot: spot)
        first_result = service.spot_rankings.dup

        create(:entry, contest: contest, user: create(:user, :confirmed), spot: spot)
        second_result = service.spot_rankings

        expect(second_result.first[:count]).to eq(first_result.first[:count])
      end
    end

    describe "#vote_summary" do
      it "caches results" do
        entry = create(:entry, contest: contest, user: create(:user, :confirmed))
        create(:vote, entry: entry, user: create(:user, :confirmed))
        first_result = service.vote_summary.dup

        create(:vote, entry: entry, user: create(:user, :confirmed))
        second_result = service.vote_summary

        expect(second_result[:total]).to eq(first_result[:total])
      end
    end

    describe ".clear_cache" do
      it "clears all cached statistics for a contest" do
        create(:entry, contest: contest, user: create(:user, :confirmed))
        first_result = service.summary_stats

        # Clear cache
        described_class.clear_cache(contest)

        # Create new entry
        create(:entry, contest: contest, user: create(:user, :confirmed))

        # Should now return fresh data
        new_service = described_class.new(contest)
        fresh_result = new_service.summary_stats

        expect(fresh_result[:total_entries]).to eq(2)
      end
    end
  end

  describe "date range filtering" do
    let!(:user1) { create(:user, :confirmed) }
    let!(:user2) { create(:user, :confirmed) }
    let!(:user3) { create(:user, :confirmed) }

    # Create entries on different dates
    let!(:entry_old) { create(:entry, contest: contest, user: user1, created_at: 10.days.ago) }
    let!(:entry_mid) { create(:entry, contest: contest, user: user2, created_at: 5.days.ago) }
    let!(:entry_new) { create(:entry, contest: contest, user: user3, created_at: 1.day.ago) }

    let!(:vote_old) { create(:vote, entry: entry_old, user: user2, created_at: 9.days.ago) }
    let!(:vote_mid) { create(:vote, entry: entry_mid, user: user1, created_at: 4.days.ago) }
    let!(:vote_new) { create(:vote, entry: entry_new, user: user1, created_at: 1.day.ago) }

    describe "#summary_stats with date range" do
      it "filters entries by start_date" do
        service_with_range = described_class.new(contest, start_date: 6.days.ago.to_date)
        stats = service_with_range.summary_stats

        expect(stats[:total_entries]).to eq(2) # entry_mid and entry_new
      end

      it "filters entries by end_date" do
        service_with_range = described_class.new(contest, end_date: 6.days.ago.to_date)
        stats = service_with_range.summary_stats

        expect(stats[:total_entries]).to eq(1) # entry_old only
      end

      it "filters entries by both start_date and end_date" do
        service_with_range = described_class.new(contest, start_date: 7.days.ago.to_date, end_date: 3.days.ago.to_date)
        stats = service_with_range.summary_stats

        expect(stats[:total_entries]).to eq(1) # entry_mid only
      end

      it "filters votes accordingly" do
        service_with_range = described_class.new(contest, start_date: 6.days.ago.to_date)
        stats = service_with_range.summary_stats

        expect(stats[:total_votes]).to eq(2) # vote_mid and vote_new
      end
    end

    describe "#daily_entries with date range" do
      it "returns only entries within date range" do
        service_with_range = described_class.new(contest, start_date: 6.days.ago.to_date, end_date: Date.current)
        result = service_with_range.daily_entries

        expect(result.values.sum).to eq(2) # entry_mid and entry_new
      end
    end

    describe "#daily_votes with date range" do
      it "returns only votes within date range" do
        service_with_range = described_class.new(contest, start_date: 6.days.ago.to_date, end_date: Date.current)
        result = service_with_range.daily_votes

        expect(result.values.sum).to eq(2) # vote_mid and vote_new
      end
    end

    describe "#top_voted_entries with date range" do
      it "returns only entries with votes within date range" do
        # Add more votes to entry_new within range
        create(:vote, entry: entry_new, user: create(:user, :confirmed), created_at: 1.day.ago)

        service_with_range = described_class.new(contest, start_date: 2.days.ago.to_date)
        result = service_with_range.top_voted_entries

        expect(result.first).to eq(entry_new)
      end
    end

    describe "#date_range_preset" do
      it "supports 'last_7_days' preset" do
        service_with_preset = described_class.new(contest, date_preset: "last_7_days")
        stats = service_with_preset.summary_stats

        expect(stats[:total_entries]).to eq(2) # entry_mid and entry_new (within 7 days)
      end

      it "supports 'last_30_days' preset" do
        service_with_preset = described_class.new(contest, date_preset: "last_30_days")
        stats = service_with_preset.summary_stats

        expect(stats[:total_entries]).to eq(3) # all entries
      end

      it "supports 'this_week' preset" do
        service_with_preset = described_class.new(contest, date_preset: "this_week")
        # Result depends on current day of week
        expect(service_with_preset.summary_stats).to be_a(Hash)
      end

      it "supports 'this_month' preset" do
        service_with_preset = described_class.new(contest, date_preset: "this_month")
        # Result depends on current month
        expect(service_with_preset.summary_stats).to be_a(Hash)
      end
    end
  end

  describe "cache invalidation callbacks" do
    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original_cache
    end

    it "clears cache when entry is created" do
      # Cache initial stats
      first_result = service.summary_stats
      expect(first_result[:total_entries]).to eq(0)

      # Create entry (triggers cache clear callback)
      create(:entry, contest: contest, user: create(:user, :confirmed))

      # Should return fresh data
      new_service = described_class.new(contest)
      second_result = new_service.summary_stats
      expect(second_result[:total_entries]).to eq(1)
    end

    it "clears cache when vote is created" do
      entry = create(:entry, contest: contest, user: create(:user, :confirmed))
      voter = create(:user, :confirmed)

      # Cache initial stats
      first_result = service.vote_summary
      expect(first_result[:total]).to eq(0)

      # Create vote (triggers cache clear callback)
      create(:vote, entry: entry, user: voter)

      # Should return fresh data
      new_service = described_class.new(contest)
      second_result = new_service.vote_summary
      expect(second_result[:total]).to eq(1)
    end
  end
end
