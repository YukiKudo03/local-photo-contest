# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def show
      @stats = dashboard_stats_service.all_stats

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

    private

    def dashboard_stats_service
      @dashboard_stats_service ||= DashboardStatsService.new
    end
  end
end
