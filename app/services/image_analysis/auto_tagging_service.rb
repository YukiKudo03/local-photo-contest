# frozen_string_literal: true

module ImageAnalysis
  class AutoTaggingService
    CATEGORY_MAP = {
      "Nature" => "scene", "Outdoors" => "scene", "Landscape" => "scene",
      "Scenery" => "scene", "Sky" => "scene", "Weather" => "scene",
      "Person" => "activity", "People" => "activity", "Sport" => "activity",
      "Animal" => "object", "Plant" => "object", "Vehicle" => "object",
      "Food" => "object", "Building" => "object", "Electronics" => "object"
    }.freeze

    def initialize(entry)
      @entry = entry
    end

    def perform
      return unless @entry.photo.attached?
      return unless aws_available?

      provider = Moderation::Providers::RekognitionProvider.new
      result = provider.detect_labels(@entry.photo)
      create_tags_from_labels(result.labels)
    rescue Moderation::Providers::RekognitionProvider::ConfigurationError => e
      Rails.logger.info("AutoTaggingService: AWS not configured, skipping: #{e.message}")
    rescue Moderation::Providers::RekognitionProvider::AnalysisError => e
      Rails.logger.error("AutoTaggingService: Analysis failed for entry #{@entry.id}: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("AutoTaggingService: Unexpected error for entry #{@entry.id}: #{e.message}")
    end

    private

    def aws_available?
      defined?(Aws::Rekognition)
    end

    def create_tags_from_labels(labels)
      labels.each do |label|
        tag = Tag.find_or_create_by!(name: label["Name"].downcase) do |t|
          t.category = infer_category(label)
        end

        EntryTag.find_or_create_by!(entry: @entry, tag: tag) do |et|
          et.confidence = label["Confidence"]
        end
      end
    end

    def infer_category(label)
      # Check parents first for category mapping
      parents = label["Parents"] || []
      parents.each do |parent|
        return CATEGORY_MAP[parent] if CATEGORY_MAP[parent]
      end

      # Check categories from Rekognition
      categories = label["Categories"] || []
      categories.each do |cat|
        return CATEGORY_MAP[cat] if CATEGORY_MAP[cat]
      end

      "general"
    end
  end
end
