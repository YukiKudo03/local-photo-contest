# frozen_string_literal: true

class ModerationJob < ApplicationJob
  queue_as :moderation

  # Retry on transient errors with exponential backoff
  retry_on Moderation::Providers::RekognitionProvider::AnalysisError,
           wait: :polynomially_longer,
           attempts: 3

  # Discard if the entry no longer exists
  discard_on ActiveJob::DeserializationError

  # Main job execution
  # @param entry_id [Integer] the ID of the entry to moderate
  def perform(entry_id)
    entry = Entry.find_by(id: entry_id)

    if entry.nil?
      Rails.logger.warn("ModerationJob: Entry #{entry_id} not found, skipping")
      return
    end

    result = Moderation::ModerationService.moderate(entry)

    if result.success?
      log_success(entry, result)
    else
      log_failure(entry, result)
    end

    # Auto-tagging after moderation (non-blocking)
    perform_auto_tagging(entry)
  rescue StandardError => e
    handle_unexpected_error(entry_id, e)
    raise # Re-raise to trigger retry
  end

  private

  def log_success(entry, result)
    if result.skipped?
      Rails.logger.info("ModerationJob: Entry #{entry.id} moderation skipped")
    else
      status = result.moderation_result&.status || "unknown"
      Rails.logger.info("ModerationJob: Entry #{entry.id} moderation completed with status: #{status}")
    end
  end

  def log_failure(entry, result)
    Rails.logger.error("ModerationJob: Entry #{entry.id} moderation failed: #{result.error}")
  end

  def perform_auto_tagging(entry)
    ImageAnalysis::AutoTaggingService.new(entry).perform
  rescue => e
    Rails.logger.warn("ModerationJob: Auto-tagging failed for entry #{entry.id}: #{e.message}")
  end

  def handle_unexpected_error(entry_id, error)
    Rails.logger.error("ModerationJob: Unexpected error for entry #{entry_id}: #{error.message}")
    Rails.logger.error(error.backtrace.first(5).join("\n"))

    # Try to set entry status to requires_review if possible
    entry = Entry.find_by(id: entry_id)
    entry&.update(moderation_status: :moderation_requires_review) if entry&.moderation_pending?
  end
end
