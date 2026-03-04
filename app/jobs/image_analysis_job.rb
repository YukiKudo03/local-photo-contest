# frozen_string_literal: true

class ImageAnalysisJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 2
  discard_on ActiveJob::DeserializationError

  def perform(entry_id)
    entry = Entry.find_by(id: entry_id)
    return unless entry&.photo&.attached?

    ImageAnalysis::QualityScoreService.new(entry).calculate
    ImageAnalysis::ImageHashService.new(entry).generate_hash
  end
end
