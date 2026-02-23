# frozen_string_literal: true

module Admin
  class TutorialAnalyticsController < Admin::BaseController
    def show
      @stats = calculate_stats
      @completion_by_type = completion_by_tutorial_type
      @completion_by_role = completion_by_user_role
      @recent_completions = recent_completions
      @skip_analysis = skip_analysis
      @daily_stats = daily_stats_last_30_days
    end

    private

    def calculate_stats
      total_users = User.count
      users_with_progress = TutorialProgress.select(:user_id).distinct.count
      completed_tutorials = TutorialProgress.where(completed: true).count
      skipped_tutorials = TutorialProgress.where(skipped: true).count
      in_progress = TutorialProgress.where(completed: false, skipped: false).count

      # 完了率計算
      total_progresses = TutorialProgress.count
      completion_rate = total_progresses > 0 ? (completed_tutorials.to_f / total_progresses * 100).round(1) : 0
      skip_rate = total_progresses > 0 ? (skipped_tutorials.to_f / total_progresses * 100).round(1) : 0

      # 平均完了時間（秒）
      avg_completion_time = TutorialProgress
        .where(completed: true)
        .where.not(started_at: nil, completed_at: nil)
        .average("EXTRACT(EPOCH FROM (completed_at - started_at))")
        &.to_i || 0

      {
        total_users: total_users,
        users_started: users_with_progress,
        users_not_started: total_users - users_with_progress,
        completed: completed_tutorials,
        skipped: skipped_tutorials,
        in_progress: in_progress,
        completion_rate: completion_rate,
        skip_rate: skip_rate,
        avg_completion_time: avg_completion_time
      }
    end

    def completion_by_tutorial_type
      TutorialProgress
        .group(:tutorial_type)
        .select(
          :tutorial_type,
          "COUNT(*) as total",
          "SUM(CASE WHEN completed = true THEN 1 ELSE 0 END) as completed_count",
          "SUM(CASE WHEN skipped = true THEN 1 ELSE 0 END) as skipped_count"
        )
        .map do |row|
          total = row.total.to_i
          completed = row.completed_count.to_i
          skipped = row.skipped_count.to_i
          completion_rate = total > 0 ? (completed.to_f / total * 100).round(1) : 0

          {
            tutorial_type: row.tutorial_type,
            total: total,
            completed: completed,
            skipped: skipped,
            in_progress: total - completed - skipped,
            completion_rate: completion_rate
          }
        end
        .sort_by { |row| -row[:completion_rate] }
    end

    def completion_by_user_role
      User.joins(:tutorial_progresses)
        .group("users.role")
        .select(
          "users.role",
          "COUNT(DISTINCT users.id) as user_count",
          "COUNT(tutorial_progresses.id) as progress_count",
          "SUM(CASE WHEN tutorial_progresses.completed = true THEN 1 ELSE 0 END) as completed_count"
        )
        .map do |row|
          progress_count = row.progress_count.to_i
          completed = row.completed_count.to_i
          completion_rate = progress_count > 0 ? (completed.to_f / progress_count * 100).round(1) : 0

          {
            role: row.role,
            user_count: row.user_count.to_i,
            progress_count: progress_count,
            completed: completed,
            completion_rate: completion_rate
          }
        end
    end

    def recent_completions
      TutorialProgress
        .includes(:user)
        .where(completed: true)
        .order(completed_at: :desc)
        .limit(10)
    end

    def skip_analysis
      # どのステップでスキップされることが多いか分析
      TutorialProgress
        .where(skipped: true)
        .where.not(current_step_id: nil)
        .joins("LEFT JOIN tutorial_steps ON tutorial_steps.step_id = tutorial_progresses.current_step_id AND tutorial_steps.tutorial_type = tutorial_progresses.tutorial_type")
        .group("tutorial_progresses.tutorial_type", "tutorial_progresses.current_step_id")
        .select(
          "tutorial_progresses.tutorial_type",
          "tutorial_progresses.current_step_id",
          "COUNT(*) as skip_count"
        )
        .order("skip_count DESC")
        .limit(10)
    end

    def daily_stats_last_30_days
      30.days.ago.to_date.upto(Date.current).map do |date|
        started = TutorialProgress.where("DATE(started_at) = ?", date).count
        completed = TutorialProgress.where("DATE(completed_at) = ?", date).where(completed: true).count
        skipped = TutorialProgress.where("DATE(completed_at) = ?", date).where(skipped: true).count

        {
          date: date.strftime("%m/%d"),
          started: started,
          completed: completed,
          skipped: skipped
        }
      end
    end
  end
end
