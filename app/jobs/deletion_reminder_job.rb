# frozen_string_literal: true

class DeletionReminderJob < ApplicationJob
  queue_as :default

  def perform
    User.deletion_reminder_due.find_each do |user|
      AccountDeletionMailer.deletion_reminder(user).deliver_later
    rescue => e
      Rails.logger.error("Deletion reminder failed for user ##{user.id}: #{e.message}")
    end
  end
end
