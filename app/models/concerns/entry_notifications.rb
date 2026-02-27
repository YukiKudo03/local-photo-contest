# frozen_string_literal: true

module EntryNotifications
  extend ActiveSupport::Concern

  included do
    after_create_commit :broadcast_new_entry_notification
    after_create_commit :send_entry_submitted_email
    after_create_commit :enqueue_exif_extraction
    after_commit :clear_statistics_cache, on: [ :create, :destroy ]
  end

  private

  def broadcast_new_entry_notification
    NotificationBroadcaster.new_entry(self)
  rescue => e
    Rails.logger.error("Failed to broadcast new entry notification: #{e.message}")
  end

  def send_entry_submitted_email
    NotificationMailer.entry_submitted(self).deliver_later
  rescue => e
    Rails.logger.error("Failed to send entry submitted email: #{e.message}")
  end

  def clear_statistics_cache
    StatisticsService.clear_cache(contest)
  rescue => e
    Rails.logger.error("Failed to clear statistics cache: #{e.message}")
  end

  def enqueue_exif_extraction
    return unless photo.attached?
    ExifExtractionJob.perform_later(id)
  rescue => e
    Rails.logger.error("Failed to enqueue EXIF extraction: #{e.message}")
  end
end
