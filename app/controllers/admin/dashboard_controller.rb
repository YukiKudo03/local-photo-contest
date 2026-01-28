# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def show
      @stats = {
        total_users: User.count,
        users_today: User.where("created_at >= ?", Date.current.beginning_of_day).count,
        total_contests: Contest.count,
        active_contests: Contest.active.count,
        total_entries: Entry.count,
        entries_today: Entry.where("created_at >= ?", Date.current.beginning_of_day).count,
        total_votes: Vote.count,
        pending_moderation: Entry.needs_moderation_review.count
      }

      @recent_users = User.order(created_at: :desc).limit(10)
      @recent_contests = Contest.includes(:user).order(created_at: :desc).limit(10)
      @recent_entries = Entry.includes(:user, :contest).order(created_at: :desc).limit(10)

      # User stats for the last 30 days
      @user_stats = User.where("created_at >= ?", 30.days.ago)
                        .group("DATE(created_at)")
                        .count
                        .transform_keys { |k| k.to_s }

      # Entry stats for the last 30 days
      @entry_stats = Entry.where("created_at >= ?", 30.days.ago)
                          .group("DATE(created_at)")
                          .count
                          .transform_keys { |k| k.to_s }
    end
  end
end
