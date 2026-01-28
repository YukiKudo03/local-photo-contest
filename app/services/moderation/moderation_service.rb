# frozen_string_literal: true

module Moderation
  # Main orchestration service for content moderation.
  # Coordinates between providers, models, and handles status updates.
  #
  # @example Basic usage
  #   result = ModerationService.moderate(entry)
  #   if result.success?
  #     puts "Moderation completed: #{result.status}"
  #   else
  #     puts "Moderation failed: #{result.error}"
  #   end
  #
  class ModerationService
    class Result
      attr_reader :entry, :moderation_result, :status, :error

      def initialize(entry:, moderation_result: nil, status:, error: nil)
        @entry = entry
        @moderation_result = moderation_result
        @status = status
        @error = error
      end

      def success?
        error.nil?
      end

      def skipped?
        status == :skipped
      end
    end

    class << self
      # Performs moderation on an entry
      # @param entry [Entry] the entry to moderate
      # @return [Result] the moderation result
      def moderate(entry)
        new(entry).moderate
      end
    end

    def initialize(entry)
      @entry = entry
      @contest = entry.contest
    end

    # Performs the moderation process
    # @return [Result] the result of moderation
    def moderate
      return skip_result("Moderation disabled for contest") unless should_moderate?
      return skip_result("No photo attached") unless photo_attached?
      return skip_result("Already moderated") if already_moderated?

      perform_moderation
    rescue Providers::ProviderNotConfiguredError, Providers::ProviderNotRegisteredError => e
      error_result(e.message, requires_review: true)
    rescue Providers::RekognitionProvider::ConfigurationError => e
      error_result("Provider configuration error: #{e.message}", requires_review: true)
    rescue Providers::RekognitionProvider::AnalysisError => e
      error_result("Analysis failed: #{e.message}", requires_review: true)
    rescue StandardError => e
      Rails.logger.error("ModerationService error for entry #{@entry.id}: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      error_result("Unexpected error: #{e.message}", requires_review: true)
    end

    private

    def should_moderate?
      Providers.enabled? && @contest.moderation_enabled?
    end

    def photo_attached?
      @entry.photo.attached?
    end

    def already_moderated?
      @entry.moderation_result.present?
    end

    def perform_moderation
      provider = Providers.current
      provider_result = provider.analyze(@entry.photo)

      ActiveRecord::Base.transaction do
        moderation_result = save_moderation_result(provider, provider_result)
        update_entry_status(provider_result)
        success_result(moderation_result)
      end
    end

    def save_moderation_result(provider, provider_result)
      ModerationResult.create!(
        entry: @entry,
        provider: provider.name,
        status: determine_result_status(provider_result),
        labels: provider_result.labels,
        max_confidence: provider_result.max_confidence,
        raw_response: provider_result.raw_response
      )
    end

    def determine_result_status(provider_result)
      return :approved unless provider_result.violation_detected?

      if exceeds_threshold?(provider_result)
        :rejected
      else
        :requires_review
      end
    end

    def exceeds_threshold?(provider_result)
      threshold = @contest.effective_moderation_threshold
      provider_result.max_confidence.present? && provider_result.max_confidence >= threshold
    end

    def update_entry_status(provider_result)
      new_status = determine_entry_status(provider_result)
      @entry.update!(moderation_status: new_status)
    end

    def determine_entry_status(provider_result)
      return :moderation_approved unless provider_result.violation_detected?

      if exceeds_threshold?(provider_result)
        :moderation_hidden
      else
        :moderation_requires_review
      end
    end

    def skip_result(reason)
      Result.new(
        entry: @entry,
        status: :skipped,
        error: nil
      ).tap do |result|
        Rails.logger.info("Moderation skipped for entry #{@entry.id}: #{reason}")
      end
    end

    def success_result(moderation_result)
      status = moderation_result.moderation_approved? ? :approved : :flagged
      Result.new(
        entry: @entry,
        moderation_result: moderation_result,
        status: status
      )
    end

    def error_result(message, requires_review: false)
      if requires_review
        @entry.update(moderation_status: :moderation_requires_review)
      end

      Result.new(
        entry: @entry,
        status: :error,
        error: message
      )
    end
  end
end
