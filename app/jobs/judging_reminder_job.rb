# frozen_string_literal: true

class JudgingReminderJob < ApplicationJob
  queue_as :default

  def perform
    Contest.where(status: :finished)
           .where(results_announced_at: nil)
           .find_each do |contest|
      next unless contest.judging_judge_only? || contest.judging_hybrid?

      contest.contest_judges.includes(:user).find_each do |cj|
        next if cj.evaluation_progress >= 100

        NotificationMailer.judging_reminder(cj).deliver_later
      end
    end
  end
end
