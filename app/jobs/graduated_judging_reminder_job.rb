# frozen_string_literal: true

class GraduatedJudgingReminderJob < ApplicationJob
  queue_as :default

  def perform
    Contest.where(status: :finished)
           .where(results_announced_at: nil)
           .where.not(judging_method: :vote_only)
           .find_each do |contest|
      process_contest(contest)
    end
  end

  private

  def process_contest(contest)
    contest.contest_judges.includes(:user).find_each do |cj|
      next unless cj.needs_reminder?

      urgency = cj.reminder_urgency
      next unless urgency

      NotificationMailer.graduated_judging_reminder(cj, urgency).deliver_later

      if urgency == :final
        NotificationMailer.judging_escalation(contest.user, cj).deliver_later
      end

      cj.record_reminder_sent!
    rescue => e
      Rails.logger.error("Graduated reminder failed for contest_judge ##{cj.id}: #{e.message}")
    end
  end
end
