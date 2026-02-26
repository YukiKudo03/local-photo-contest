# frozen_string_literal: true

class JudgingDeadlineJob < ApplicationJob
  queue_as :default

  DEADLINE_WARNING_DAYS = [ 7, 3, 1 ].freeze

  def perform
    Contest.where(status: :finished)
           .where(results_announced_at: nil)
           .where.not(entry_end_at: nil)
           .find_each do |contest|
      days_remaining = (contest.entry_end_at.to_date - Date.current).to_i
      next unless DEADLINE_WARNING_DAYS.include?(days_remaining)

      next unless contest.judging_judge_only? || contest.judging_hybrid?

      contest.contest_judges.includes(:user).find_each do |cj|
        next if cj.evaluation_progress >= 100

        NotificationMailer.judging_deadline(cj, days_remaining).deliver_later
      end
    end
  end
end
