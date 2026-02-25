# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DashboardStatsService do
  # Use memory store for caching tests
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache
  end

  describe "#all_stats" do
    subject(:service) { described_class.new }

    context "with no data" do
      it "returns zero counts" do
        stats = service.all_stats

        expect(stats[:total_users]).to eq(0)
        expect(stats[:total_contests]).to eq(0)
        expect(stats[:total_entries]).to eq(0)
        expect(stats[:total_votes]).to eq(0)
      end
    end

    context "with existing data" do
      let!(:users) { create_list(:user, 3, :confirmed) }
      let!(:contest) { create(:contest, :published) }
      let!(:entries) { create_list(:entry, 2, contest: contest) }

      before do
        create(:vote, entry: entries.first, user: users.first)
        create(:vote, entry: entries.second, user: users.second)
      end

      it "returns correct total user count" do
        stats = service.all_stats
        # 3 users + contest organizer + 2 entry users = potentially more users
        expect(stats[:total_users]).to be >= 3
      end

      it "returns correct total contest count" do
        stats = service.all_stats
        expect(stats[:total_contests]).to eq(1)
      end

      it "returns correct total entry count" do
        stats = service.all_stats
        expect(stats[:total_entries]).to eq(2)
      end

      it "returns correct total vote count" do
        stats = service.all_stats
        expect(stats[:total_votes]).to eq(2)
      end

      it "returns active contests count" do
        stats = service.all_stats
        expect(stats[:active_contests]).to eq(1)
      end
    end

    context "with today's data" do
      it "counts users created today" do
        # Create an old user first
        create(:user, :confirmed, created_at: 2.days.ago)
        old_count = service.all_stats[:users_today]
        service.clear_cache

        # Now create new users today
        create_list(:user, 2, :confirmed, created_at: Time.current)
        service.clear_cache

        stats = service.all_stats
        expect(stats[:users_today]).to eq(old_count + 2)
      end

      it "counts entries created today" do
        contest = create(:contest, :published)
        # Create entry from yesterday
        create(:entry, contest: contest, created_at: 1.day.ago)
        old_count = service.all_stats[:entries_today]
        service.clear_cache

        # Create entries today
        create_list(:entry, 3, contest: contest, created_at: Time.current)
        service.clear_cache

        stats = service.all_stats
        expect(stats[:entries_today]).to eq(old_count + 3)
      end
    end

    context "with pending moderation entries" do
      let!(:contest) { create(:contest, :published) }

      before do
        create(:entry, contest: contest, moderation_status: :moderation_approved)
        create(:entry, contest: contest, moderation_status: :moderation_requires_review)
        create(:entry, contest: contest, moderation_status: :moderation_requires_review)
      end

      it "returns correct pending_moderation count" do
        stats = service.all_stats
        expect(stats[:pending_moderation]).to eq(2)
      end
    end
  end

  describe "caching" do
    subject(:service) { described_class.new }

    let!(:user) { create(:user, :confirmed) }

    it "caches results" do
      # First call
      first_result = service.all_stats

      # Add a new user (should not affect cached result)
      create(:user, :confirmed)

      # Second call should return cached result
      second_result = service.all_stats

      expect(second_result[:total_users]).to eq(first_result[:total_users])
    end

    it "returns fresh data after cache clear" do
      # First call
      first_result = service.all_stats
      initial_count = first_result[:total_users]

      # Clear cache
      service.clear_cache

      # Add a new user
      create(:user, :confirmed)

      # Next call should return fresh data
      fresh_result = service.all_stats
      expect(fresh_result[:total_users]).to eq(initial_count + 1)
    end
  end

  describe "query efficiency" do
    let!(:users) { create_list(:user, 5, :confirmed) }
    let!(:contest) { create(:contest, :published) }
    let!(:entries) { create_list(:entry, 3, contest: contest) }

    it "executes reasonable number of queries" do
      service = described_class.new
      service.clear_cache

      query_count = 0
      counter = lambda { |_name, _start, _finish, _id, payload|
        query_count += 1 unless payload[:sql].include?("SCHEMA") || payload[:sql].include?("TRANSACTION")
      }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        service.all_stats
      end

      # Should be at most 8 queries (one per stat), caching will reduce this to 0 on subsequent calls
      expect(query_count).to be <= 8, "Expected at most 8 queries but got #{query_count}"
    end

    it "uses cached results on subsequent calls" do
      service = described_class.new
      service.clear_cache

      # First call to populate cache
      service.all_stats

      # Count queries on second call
      query_count = 0
      counter = lambda { |_name, _start, _finish, _id, payload|
        query_count += 1 unless payload[:sql].include?("SCHEMA") || payload[:sql].include?("TRANSACTION")
      }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        service.all_stats
      end

      # Should be 0 queries (using cache)
      expect(query_count).to eq(0), "Expected 0 queries (cached) but got #{query_count}"
    end
  end
end
