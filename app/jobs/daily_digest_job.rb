# frozen_string_literal: true

class DailyDigestJob < ApplicationJob
  queue_as :default

  def perform
    yesterday = 1.day.ago.all_day

    User.where(role: [ :organizer, :admin ], email_digest: true).find_each do |organizer|
      contests = organizer.contests.active.where(status: [ :published, :finished ])
      next if contests.empty?

      contests_with_entries = {}
      contests.each do |contest|
        new_entries = contest.entries.where(created_at: yesterday)
        contests_with_entries[contest] = new_entries.includes(:user).to_a if new_entries.any?
      end

      next if contests_with_entries.empty?

      NotificationMailer.daily_digest(organizer, contests_with_entries).deliver_now
    end
  end
end
