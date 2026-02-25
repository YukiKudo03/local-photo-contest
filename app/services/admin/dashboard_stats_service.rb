# frozen_string_literal: true

module Admin
  class DashboardStatsService
    CACHE_KEY = "admin/dashboard_stats"
    CACHE_TTL = 5.minutes

    def all_stats
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
        fetch_all_stats
      end
    end

    def clear_cache
      Rails.cache.delete(CACHE_KEY)
    end

    private

    def fetch_all_stats
      today_start = Date.current.beginning_of_day

      {
        total_users: User.count,
        users_today: User.where("created_at >= ?", today_start).count,
        total_contests: Contest.count,
        active_contests: Contest.active.count,
        total_entries: Entry.count,
        entries_today: Entry.where("created_at >= ?", today_start).count,
        total_votes: Vote.count,
        pending_moderation: Entry.needs_moderation_review.count
      }
    end
  end
end
