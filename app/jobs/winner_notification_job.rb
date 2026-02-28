# frozen_string_literal: true

class WinnerNotificationJob < ApplicationJob
  queue_as :default

  def perform(contest_id = nil)
    if contest_id
      contest = Contest.find(contest_id)
      WinnerNotificationService.new(contest).notify_winners!
    else
      scan_and_notify
    end
  end

  private

  def scan_and_notify
    Contest.where(status: :finished)
           .where.not(results_announced_at: nil)
           .find_each do |contest|
      next unless contest.contest_rankings
                         .where("rank <= ?", contest.prize_count || 3)
                         .where(winner_notified_at: nil)
                         .exists?

      WinnerNotificationService.new(contest).notify_winners!
    rescue => e
      Rails.logger.error("Winner notification scan failed for contest ##{contest.id}: #{e.message}")
    end
  end
end
